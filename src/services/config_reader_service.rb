require 'yaml'
require_relative '../constants/config_constants'

class ConfigReaderService
  def initialize(config_file)
    @config = read_file(config_file)
  end

  def read_file(config_file)
    YAML.load_file(config_file)
  end

  def configured_task_templates
    @config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
  end

  def configured_template_by_name(name)
    configured_task_templates[name]
  end

  def configured_lg_templates
    @config[ConfigConstants::KEYS[:LG_TEMPLATES]]
  end

  def configured_tasks
    @config[ConfigConstants::KEYS[:TASKS]].to_a.reverse.to_h
  end
end
