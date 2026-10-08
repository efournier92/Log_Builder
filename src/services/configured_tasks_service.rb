require_relative './config_reader_service'
require_relative './task_printer_service'
require_relative './tag_merge_service'
require_relative './add_task_service'
require_relative '../models/year'
require_relative '../constants/config_constants'

class ConfiguredTasksService
  def add_configured_tasks(year)
    config_file = year.config_file
    reader = ConfigReaderService.new(config_file)
    tags = reader.configured_tasks

    return if tags.nil?

    add_task_service = AddTaskService.new(reader.tag_order)

    tags.each_value do |config|
      printer = TaskPrinterService.new(config_file)
      method = config[ConfigConstants::KEYS[:METHOD]]
      template_key = config[ConfigConstants::KEYS[:TEMPLATE]]
      templates = reader.configured_task_templates
      template = templates.is_a?(Hash) ? templates[template_key] : nil
      template_variables = config[ConfigConstants::KEYS[:TEMPLATE_VARIABLES]]

      if template.nil? && template_key.is_a?(String)
        raise ConfigReaderService::InvalidConfigError,
              format(ConfigConstants::ERRORS[:INVALID_CONFIG], "no template named '#{template_key}'")
      end

      template = template_key if template.nil? && (template_key.is_a?(Hash) || template_key.is_a?(Array))

      template_variables = with_birth_year(config, method, template, template_variables, year)

      resolved = printer.resolve_template(template, template_variables)
      config[ConfigConstants::KEYS[:TAG]] = TagMergeService.roots_from_template(resolved)

      add_task_service.public_send(method, year, config)
    end

    year
  end

  private

  def with_birth_year(config, method, template, template_variables, year)
    return template_variables unless config.key?(ConfigConstants::KEYS[:BIRTH_YEAR])

    birth_year = config[ConfigConstants::KEYS[:BIRTH_YEAR]]

    unless method == ConfigConstants::BIRTH_YEAR_METHODS[:SPECIFIC_DATE]
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'birth_year is only supported with to_specific_date')
    end

    unless birth_year.is_a?(Integer)
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'birth_year must be an integer')
    end

    if birth_year > year.year_number
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'birth_year cannot be in the future')
    end

    unless template_includes?(template, ConfigConstants::PLACEHOLDERS[:AGE])
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'birth_year requires {{AGE}} in the template')
    end

    template_variables = [] if template_variables.nil?
    template_variables + [{ ConfigConstants::PLACEHOLDERS[:AGE] => (year.year_number - birth_year).to_s }]
  end

  def template_includes?(node, token)
    case node
    when Hash
      node.any? { |key, value| template_includes?(key, token) || template_includes?(value, token) }
    when Array
      node.any? { |element| template_includes?(element, token) }
    when String
      node.include?(token)
    else
      false
    end
  end
end
