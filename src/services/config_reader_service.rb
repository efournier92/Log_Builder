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
    parse_problems, config, lines = parse_config(config_file)
    raise_report(parse_problems, config_file) if parse_problems.any?

    problems = structure_problems(config, mode, lines)
    raise_report(problems, config_file) if problems.any?

    config
  end

  def self.parse_config(config_file)
    contents = read_contents(config_file)

    begin
      ast = Psych.parse(contents)
    rescue Psych::SyntaxError => e
      return [["YAML syntax error: #{e.message}"], nil, {}]
    end

    problems = duplicate_key_problems(ast)
    config = materialize(config_file, problems)
    [problems, config, line_index(ast)]
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

  # Psych `start_line` is 0-based; report 1-based lines.
  def self.line_index(ast)
    index = {}
    root = ast.is_a?(Psych::Nodes::Document) ? ast.root : ast
    return index unless root.is_a?(Psych::Nodes::Mapping)

    root.children.each_slice(2) do |key, value|
      next unless key.is_a?(Psych::Nodes::Scalar)

      index[key.value] = key.start_line + 1
      index.merge!(child_line_index(key.value, value))
    end
    index
  end

  def self.child_line_index(section, node)
    return {} unless node.is_a?(Psych::Nodes::Mapping)

    node.children.each_slice(2).each_with_object({}) do |(key, _value), index|
      index["#{section}.#{key.value}"] = key.start_line + 1 if key.is_a?(Psych::Nodes::Scalar)
    end
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

      identity = key.plain ? [:plain, name] : [:quoted, name]
      problems << "duplicate key '#{name}' in #{section} (line #{key.start_line + 1})" if seen[identity]
      seen[identity] = true
    end
  end

  def self.structure_problems(config, mode, lines)
    return ['root must be a mapping'] unless config.is_a?(Hash)

    problems = unknown_top_level_problems(config, lines)
    problems.concat(section_type_problems(config))
    tasks = config[ConfigConstants::KEYS[:TASKS]]
    problems.concat(missing_template_section_problems(config, tasks))
    problems.concat(missing_lg_section_problems(config, mode, lines))
    problems.concat(template_value_problems(config, lines))
    problems.concat(tag_order_problems(config))
    problems.concat(task_problems(config, tasks, lines))
    problems
  end

  def self.unknown_top_level_problems(config, lines)
    config.each_key.map do |key|
      next if ALLOWED_TOP_LEVEL_KEYS.include?(key)

      suggestion = allowed_key_suggestion(key)
      message = "unknown top-level key '#{key}'"
      message = "#{message} (did you mean '#{suggestion}'?)" if suggestion
      with_line(message, lines[key])
    end.compact
  end

  def self.allowed_key_suggestion(key)
    return nil unless key.is_a?(String)

    ALLOWED_TOP_LEVEL_KEYS.find { |allowed| allowed.include?(key) || key.include?(allowed) }
  end

  def self.with_line(message, line)
    line ? "#{message} (line #{line})" : message
  end

  def self.section_type_problems(config)
    {
      ConfigConstants::KEYS[:TASKS] => 'mapping',
      ConfigConstants::KEYS[:TASK_TEMPLATES] => 'mapping',
      ConfigConstants::KEYS[:LG_TEMPLATES] => 'mapping'
    }.map do |key, type|
      value = config[key]
      "#{key} must be a #{type}" if !value.nil? && !value.is_a?(Hash)
    end.compact
  end

  def self.template_value_problems(config, lines)
    templates = config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
    return [] unless templates.is_a?(Hash)

    templates.map do |name, value|
      next if value.is_a?(Hash) || value.is_a?(Array)

      with_line("task_templates_config['#{name}']: template must be a mapping or a list",
                lines["task_templates_config.#{name}"])
    end.compact
  end

  # The marker is the ordering sentinel, so it is a valid entry; only repeats are wrong.
  def self.tag_order_problems(config)
    tag_order = config[ConfigConstants::KEYS[:TAG_ORDER]]
    return [] if tag_order.nil?
    return ['tag_order_config must be a list'] unless tag_order.is_a?(Array)

    seen = {}
    tag_order.each_with_object([]) do |entry, problems|
      unless entry.is_a?(String)
        problems << 'tag_order_config entries must be strings'
        next
      end

      problems << "duplicate tag_order_config entry: #{entry}" if seen[entry]
      seen[entry] = true
    end.uniq
  end

  def self.missing_template_section_problems(config, tasks)
    return [] unless tasks.is_a?(Hash) && !tasks.empty?
    return [] unless config[ConfigConstants::KEYS[:TASK_TEMPLATES]].nil?

    ['task_templates_config is required when tasks_config is present']
  end

  def self.missing_lg_section_problems(config, mode, lines)
    return [] unless mode.to_s == AppConstants::MODES[:LG]

    lg_templates = config[ConfigConstants::KEYS[:LG_TEMPLATES]]
    return ['lg_templates_config is required when mode is LG'] if lg_templates.nil?
    return [] unless lg_templates.is_a?(Hash)

    problems = LG_TEMPLATE_KEYS.map do |key|
      line = lines["lg_templates_config.#{key}"]
      next with_line("lg_templates_config: missing required key '#{key}'", line) unless lg_templates.key?(key)

      value = lg_templates[key]
      with_line("lg_templates_config: '#{key}' must be a non-nil String or list", line) unless string_or_array?(value)
    end.compact

    base = lg_templates[ConfigConstants::KEYS[:LG_TEMPLATE_BASE]]
    return problems unless string_or_array?(base)

    expected = base.is_a?(Array) ? 'must be a list' : 'must be a string'
    lg_templates.each do |key, value|
      next if key == ConfigConstants::KEYS[:LG_TEMPLATE_BASE]
      next if string_or_array?(value) && value.instance_of?(base.class)
      # A bad base/weekday/weekend value is already named by the required-key loop above.
      next if !string_or_array?(value) && LG_TEMPLATE_KEYS.include?(key)

      line = lines["lg_templates_config.#{key}"]
      message = if string_or_array?(value)
                  "lg_templates_config: '#{key}' #{expected}, matching 'base'"
                else
                  "lg_templates_config: '#{key}' must be a non-nil String or list"
                end
      problems << with_line(message, line)
    end

    problems
  end

  def self.string_or_array?(value)
    value.is_a?(String) || value.is_a?(Array)
  end

  def self.task_problems(config, tasks, lines)
    return [] unless tasks.is_a?(Hash)

    templates = config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
    valid_methods = AddTaskService.instance_methods(false).map(&:to_s)

    tasks.each_with_object([]) do |(task_name, task), problems|
      label = task_label(task_name, lines)
      unless task.is_a?(Hash)
        problems << "#{label}: task must be a mapping"
        next
      end

      method = task[ConfigConstants::KEYS[:METHOD]]
      known_method = valid_methods.include?(method)
      problems << "#{label}: unknown method '#{method}' (valid: #{valid_methods.join(', ')})" unless known_method
      problems.concat(method_key_problems(label, method, task)) if known_method
      problems.concat(value_type_problems(label, method, task)) if known_method
      problems.concat(each_flag_problems(label, task))
      problems.concat(birth_year_problems(label, method, task))
      problems.concat(template_variable_problems(label, task))
      problems.concat(template_problems(label, task, templates))
      problems.concat(template_resolution_problems(label, task, templates))
    end
  end

  def self.task_label(task_name, lines)
    with_line("tasks_config['#{task_name}']", lines["tasks_config.#{task_name}"])
  end

  def self.birth_year_problems(label, method, task)
    return [] unless task.key?(ConfigConstants::KEYS[:BIRTH_YEAR])

    value = task[ConfigConstants::KEYS[:BIRTH_YEAR]]
    problems = []
    problems << "#{label}: 'birth_year' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
    unless method == ConfigConstants::BIRTH_YEAR_METHODS[:SPECIFIC_DATE]
      problems << "#{label}: 'birth_year' is only supported with to_specific_date"
    end
    problems
  end

  def self.template_variable_problems(label, task)
    key = ConfigConstants::KEYS[:TEMPLATE_VARIABLES]
    return [] unless task.key?(key)
    return [] if task[key].is_a?(Array)

    ["#{label}: 'template_variables' must be a list"]
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
        unless value.is_a?(Integer)
          problems << "#{label}: 'month' must be an Integer (got #{value.class}); write month: 12, not \"12\""
        end
        problems << "#{label}: 'month' must be between 1 and 12" if value.is_a?(Integer) && !(1..12).cover?(value)
      when ConfigConstants::KEYS[:DAY]
        problems << "#{label}: 'day' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
        problems << "#{label}: 'day' must be between 1 and 31" if value.is_a?(Integer) && !(1..31).cover?(value)
      when ConfigConstants::KEYS[:NTH_DAY]
        problems << "#{label}: 'nth_day' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
        problems << "#{label}: 'nth_day' must be between 1 and 31" if value.is_a?(Integer) && !(1..31).cover?(value)
      when ConfigConstants::KEYS[:N_WEEKS]
        problems << "#{label}: 'n_weeks' must be an Integer (got #{value.class})" unless value.is_a?(Integer)
        problems << "#{label}: 'n_weeks' must be at least 1" if value.is_a?(Integer) && value < 1
      when ConfigConstants::KEYS[:DAY_NAME]
        unless Year.valid_day_name?(value)
          valid = Year::DAY_NAMES.join(', ')
          problems << "#{label}: invalid day name '#{value}' (valid: #{valid}, capitalized)"
        end
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
    unless value.is_a?(String) || value.is_a?(Hash) || value.is_a?(Array)
      return ["#{label}: 'template' must name a template or be an inline mapping/list"]
    end
    return [] unless value.is_a?(String)
    # The missing/wrong section is reported once; without this every task repeats it.
    return [] unless templates.is_a?(Hash)

    lookup = templates[value]
    lookup.nil? ? ["#{label}: no template named '#{value}'"] : []
  end

  def self.template_resolution_problems(label, task, templates)
    template = task_template(task, templates)
    return [] if template.nil?

    variables = task[ConfigConstants::KEYS[:TEMPLATE_VARIABLES]]
    variables = [] unless variables.is_a?(Array)
    variables += [{ ConfigConstants::PLACEHOLDERS[:AGE] => '0' }] if task.key?(ConfigConstants::KEYS[:BIRTH_YEAR])

    resolved = resolved_template(template, variables)
    reserved_root_problems(label, resolved) + placeholder_problems(label, resolved, templates)
  end

  def self.reserved_root_problems(label, template)
    root_names = case template
                 when Hash then template.keys
                 when Array then template
                 when String then [template]
                 else []
                 end

    return [] unless root_names.include?(ConfigConstants::TAG_ORDER_MARKER)

    ["#{label}: tag name is reserved: #{ConfigConstants::TAG_ORDER_MARKER}"]
  end

  def self.task_template(task, templates)
    value = task[ConfigConstants::KEYS[:TEMPLATE]]
    return value if value.is_a?(Hash) || value.is_a?(Array)
    return nil unless value.is_a?(String) && templates.is_a?(Hash)

    templates[value]
  end

  # Mirrors TaskPrinterService#resolve_template/#update_content_hash; requiring task_printer_service here would cycle.
  def self.resolved_template(template, variables)
    copy = Marshal.load(Marshal.dump(template))
    substitute_variables(copy, variables)
    copy
  end

  def self.substitute_variables(node, variables)
    if node.is_a?(Hash)
      node.each_value { |value| substitute_variables(value, variables) }
    elsif node.is_a?(Array)
      node.map! { |element| substitute_element(element, variables) }
    end
    node
  end

  def self.substitute_element(element, variables)
    return element unless element.is_a?(String)

    placeholder = element[/\{\{.*?\}\}/m]
    return element if placeholder.nil?

    mapping = variables.detect { |entry| entry.is_a?(Hash) && entry.keys[0] == placeholder }
    mapping ? element.gsub(placeholder, mapping.values[0].to_s) : element
  end

  def self.placeholder_problems(label, node, templates)
    case node
    when Hash
      node.flat_map do |key, value|
        template_reference_problems(label, key, templates) + placeholder_problems(label, value, templates)
      end
    when Array
      node.flat_map { |element| placeholder_problems(label, element, templates) }
    when String
      node.match?(/\{\{(?!TASK\.)/) ? ["#{label}: unresolved placeholder '#{node}'"] : []
    else
      []
    end
  end

  def self.template_reference_problems(label, key, templates)
    return [] unless key.is_a?(String) && key.include?('{{') && key.include?('}}')
    return [] unless templates.is_a?(Hash)

    name = key[/\{\{(.*?)\}\}/m, 1]
    return [] if name.nil? || name.start_with?('TASK.')

    target = templates[name]
    return ["#{label}: no template named '#{name}'"] if target.nil?
    return ["#{label}: template '#{name}' is not a mapping"] unless target.is_a?(Hash)

    []
  end

  def self.report(config_file, problems)
    format(AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_REPORT], ([config_file] + problems).join("\n"))
  end

  def self.raise_report(problems, config_file)
    raise InvalidConfigError, report(config_file, problems)
  end
  private_class_method :parse_config, :materialize, :read_contents, :line_index, :child_line_index,
                       :duplicate_key_problems, :mapping_duplicates, :structure_problems,
                       :unknown_top_level_problems, :allowed_key_suggestion, :with_line, :section_type_problems,
                       :template_value_problems, :tag_order_problems, :missing_template_section_problems,
                       :missing_lg_section_problems, :string_or_array?, :task_problems, :task_label,
                       :method_key_problems, :value_type_problems, :each_flag_problems,
                       :birth_year_problems, :template_variable_problems, :template_problems,
                       :template_resolution_problems, :reserved_root_problems, :task_template, :resolved_template,
                       :substitute_variables, :substitute_element, :placeholder_problems,
                       :template_reference_problems, :raise_report

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
