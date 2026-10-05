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
    add_task_service = AddTaskService.new
    tags = reader.configured_tasks

    return if tags.nil?

    tags.each_value do |config|
      printer = TaskPrinterService.new(config_file)
      method = config[ConfigConstants::KEYS[:METHOD]]
      template = reader.configured_task_templates[config[ConfigConstants::KEYS[:TEMPLATE]]]
      template_variables = config[ConfigConstants::KEYS[:TEMPLATE_VARIABLES]]

      template = config[ConfigConstants::KEYS[:TEMPLATE]] if template.nil?

      resolved = printer.resolve_template(template, template_variables)
      config[ConfigConstants::KEYS[:TAG]] = TagMergeService.roots_from_template(resolved)

      add_task_service.public_send(method, year, config)
    end

    year
  end
end
