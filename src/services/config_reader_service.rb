require 'yaml'
require_relative '../constants/config_constants'
require_relative '../constants/app_constants'
require_relative './add_task_service'

class ConfigReaderService
  class FileNotFoundError < StandardError; end
  class InvalidConfigError < StandardError; end

  ALLOWED_TOP_LEVEL_KEYS = %w[
    tasks_config
    task_templates_config
    lg_templates_config
    tag_order_config
  ].freeze

  LG_TEMPLATE_KEYS = %w[base weekday weekend].freeze

  # `required_unless` maps a key to the condition key that makes it optional.
  TASK_METHOD_RULES = {
    'to_specific_date' => { 'required' => %w[day], 'required_unless' => { 'month' => 'is_each' } },
    'to_each_day' => { 'forbidden' => %w[day_name] },
    'to_each_weekday' => { 'forbidden' => %w[day_name] },
    'to_each_weekend' => { 'forbidden' => %w[day_name] },
    'to_each_xday' => { 'required' => %w[day_name] },
    'to_nth_xday_in_month' => { 'required' => %w[day_name nth_day], 'required_unless' => { 'month' => 'is_each' } },
    'to_nth_xday_in_each_month' => { 'required' => %w[day_name nth_day] },
    'to_last_xday_in_month' => { 'required' => %w[day_name month] },
    'to_last_xday_in_each_month' => { 'required' => %w[day_name] },
    'to_last_day_in_month' => { 'required' => %w[month] },
    'to_last_day_in_each_month' => {},
    'to_nth_day_in_each_month' => { 'required' => %w[nth_day] },
    'to_nth_day_in_each_quarter' => { 'required' => %w[nth_day] },
    'to_xday_every_n_weeks' => { 'required' => %w[day_name n_weeks] },
    'to_easter' => {},
    'to_good_friday' => {}
  }.freeze

  def initialize(config_file)
    @config = read_file(config_file)
  end

  def read_file(config_file)
    unless File.exist?(config_file)
      raise FileNotFoundError, format(ConfigConstants::ERRORS[:FILE_NOT_FOUND], config_file)
    end

    YAML.load_file(config_file)
  end

  def self.validate!(config_file, mode:)
    parse_problems, config = parse_config(config_file)
    raise_report(parse_problems) if parse_problems.any?

    problems = structure_problems(config, mode)
    raise_report(problems) if problems.any?

    config
  end

  def self.parse_config(config_file)
    contents = read_contents(config_file)

    begin
      ast = Psych.parse(contents)
    rescue Psych::SyntaxError => e
      return [["YAML syntax error: #{e.message}"], nil]
    end

    problems = duplicate_key_problems(ast)
    config = materialize(config_file, problems)
    [problems, config]
  end

  # Psych 4/5 reject aliases by default; Psych 3 allows them. Surface the README caveat, not a backtrace.
  def self.materialize(config_file, problems)
    YAML.load_file(config_file)
  rescue Psych::SyntaxError => e
    problems << "YAML syntax error: #{e.message}"
    nil
  rescue Psych::Exception
    problems << 'YAML syntax error: aliases and anchors are not portable across Psych versions; avoid them'
    nil
  end

  def self.read_contents(config_file)
    unless File.exist?(config_file)
      raise FileNotFoundError, format(ConfigConstants::ERRORS[:FILE_NOT_FOUND], config_file)
    end

    File.read(config_file, encoding: 'UTF-8')
  end

  def self.duplicate_key_problems(node, section = 'top level')
    case node
    when Psych::Nodes::Document
      duplicate_key_problems(node.root, section)
    when Psych::Nodes::Mapping
      problems = mapping_duplicates(node, section)
      node.children.each_slice(2) do |key, value|
        child_section = section == 'top level' && key.is_a?(Psych::Nodes::Scalar) ? key.value : section
        problems.concat(duplicate_key_problems(value, child_section))
      end
      problems
    when Psych::Nodes::Sequence
      node.children.flat_map { |child| duplicate_key_problems(child, section) }
    else
      []
    end
  end

  def self.mapping_duplicates(mapping, section)
    seen = {}
    mapping.children.each_slice(2).each_with_object([]) do |(key, _value), problems|
      next unless key.is_a?(Psych::Nodes::Scalar)

      name = key.value
      # `<<` is an alias-backed merge key, unsupported on the target Psych versions.
      next if name == '<<'

      problems << "duplicate key '#{name}' in #{section}" if seen[name]
      seen[name] = true
    end
  end

  def self.structure_problems(config, mode)
    return [] unless config.is_a?(Hash)

    problems = unknown_top_level_problems(config)
    tasks = config[ConfigConstants::KEYS[:TASKS]]
    problems.concat(missing_template_section_problems(config, tasks))
    problems.concat(missing_lg_section_problems(config, mode))
    problems.concat(task_problems(config, tasks))
    problems
  end

  def self.unknown_top_level_problems(config)
    config.each_key.map do |key|
      "unknown top-level key '#{key}'" unless ALLOWED_TOP_LEVEL_KEYS.include?(key)
    end.compact
  end

  def self.missing_template_section_problems(config, tasks)
    return [] unless tasks.is_a?(Hash) && !tasks.empty?
    return [] unless config[ConfigConstants::KEYS[:TASK_TEMPLATES]].nil?

    ['task_templates_config is required when tasks_config is present']
  end

  def self.missing_lg_section_problems(config, mode)
    return [] unless mode.to_s == AppConstants::MODES[:LG]

    lg_templates = config[ConfigConstants::KEYS[:LG_TEMPLATES]]
    return ['lg_templates_config is required when mode is LG'] if lg_templates.nil?

    LG_TEMPLATE_KEYS.map do |key|
      "lg_templates_config: missing required key '#{key}'" unless lg_templates.key?(key)
    end.compact
  end

  def self.task_problems(config, tasks)
    return [] unless tasks.is_a?(Hash)

    templates = config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
    valid_methods = AddTaskService.instance_methods(false).map(&:to_s)

    tasks.each_with_object([]) do |(task_name, task), problems|
      label = "tasks_config['#{task_name}']"
      unless task.is_a?(Hash)
        problems << "#{label}: task must be a mapping"
        next
      end

      method = task[ConfigConstants::KEYS[:METHOD]]
      known_method = valid_methods.include?(method)
      problems << "#{label}: unknown method '#{method}'" unless known_method
      problems.concat(method_key_problems(label, method, task)) if known_method
      problems.concat(value_type_problems(label, method, task)) if known_method
      problems.concat(each_flag_problems(label, task))
      problems.concat(template_problems(label, task, templates))
    end
  end

  def self.method_key_problems(label, method, task)
    rules = TASK_METHOD_RULES[method] || {}

    (rules['required'] || []).map do |key|
      "#{label}: missing required key '#{key}' for #{method}" unless task.key?(key)
    end.concat(
      (rules['required_unless'] || {}).map do |key, condition|
        next if task.key?(key) || task[condition]

        "#{label}: missing required key '#{key}' for #{method}"
      end
    ).concat(
      (rules['forbidden'] || []).map do |key|
        "#{label}: key '#{key}' is not allowed for #{method}" if task.key?(key)
      end
    ).compact
  end

  def self.value_type_problems(label, method, task)
    rules = TASK_METHOD_RULES[method] || {}
    keys = ((rules['required'] || []) + (rules['required_unless'] || {}).keys).uniq

    keys.each_with_object([]) do |key, problems|
      next unless task.key?(key)

      value = task[key]
      case key
      when ConfigConstants::KEYS[:MONTH]
        problems << "#{label}: 'month' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
        problems << "#{label}: 'month' must be between 1 and 12" if value.is_a?(Integer) && !(1..12).cover?(value)
      when ConfigConstants::KEYS[:DAY]
        problems << "#{label}: 'day' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
      when ConfigConstants::KEYS[:NTH_DAY]
        problems << "#{label}: 'nth_day' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
        problems << "#{label}: 'nth_day' must be between 1 and 31" if value.is_a?(Integer) && !(1..31).cover?(value)
      when ConfigConstants::KEYS[:N_WEEKS]
        problems << "#{label}: 'n_weeks' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
        problems << "#{label}: 'n_weeks' must be at least 1" if value.is_a?(Integer) && value < 1
      when ConfigConstants::KEYS[:DAY_NAME]
        problems << "#{label}: invalid day name '#{value}'" unless Year.valid_day_name?(value)
      end
    end
  end

  def self.each_flag_problems(label, task)
    key = ConfigConstants::KEYS[:IS_EACH?]
    return [] unless task.key?(key)

    value = task[key]
    return [] if [true, false].include?(value)

    ["#{label}: 'is_each' must be true or false"]
  end

  def self.template_problems(label, task, templates)
    template_key = ConfigConstants::KEYS[:TEMPLATE]
    return ["#{label}: missing required key 'template'"] unless task.key?(template_key)

    value = task[template_key]
    return [] unless value.is_a?(String)

    lookup = templates.is_a?(Hash) ? templates[value] : nil
    lookup.nil? ? ["#{label}: no template named '#{value}'"] : []
  end

  def self.raise_report(problems)
    raise InvalidConfigError,
          format(AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_REPORT], problems.join("\n"))
  end
  private_class_method :parse_config, :materialize, :read_contents, :duplicate_key_problems, :mapping_duplicates,
                       :structure_problems, :unknown_top_level_problems, :missing_template_section_problems,
                       :missing_lg_section_problems, :task_problems, :method_key_problems, :value_type_problems,
                       :each_flag_problems, :template_problems, :raise_report

  def configured_task_templates
    @config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
  end

  def configured_template_by_name(name)
    configured_task_templates && configured_task_templates[name]
  end

  def configured_lg_templates
    @config[ConfigConstants::KEYS[:LG_TEMPLATES]]
  end

  def configured_tasks
    @config[ConfigConstants::KEYS[:TASKS]].to_a.reverse.to_h
  end

  def tag_order
    @config.fetch(ConfigConstants::KEYS[:TAG_ORDER], [])
  end
end
