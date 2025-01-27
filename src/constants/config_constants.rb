module ConfigConstants
  KEYS = {
    TASKS: 'tasks_config',
    TASK_TEMPLATES: 'task_templates_config',
    LG_TEMPLATES: 'lg_templates_config',
    LG_TEMPLATE_BASE: 'base',
    LG_TEMPLATE_WEEKDAY: 'weekday',
    LG_TEMPLATE_WEEKEND: 'weekend',
    TEMPLATE: 'template',
    TEMPLATE_VARIABLES: 'template_variables',
    SPECIFIC_DATE: 'specific_date',
    METHOD: 'method',
    CONTENT: 'content',
    TAG: 'tag',
    MONTH: 'month',
    QUARTER: 'quarter',
    DAY: 'day',
    NTH_DAY: 'nth_day',
    DAY_NAME: 'day_name',
    N_WEEKS: 'n_weeks',
    IS_EACH?: 'is_each',
    EVEN_ONLY?: 'even_only',
    ODD_ONLY?: 'odd_only',
  }.freeze

  PLACEHOLDERS = {
    TEMPLATE_START: '{{',
    TEMPLATE_END: '}}',
    CONTENT: '{{CONTENT}}'
  }.freeze

  CONFIGURED_TASK_METHODS = {
    SPECIFIC_DATE: 'to_specific_date',
  }.freeze

  TEMPLATE_TYPES = {
    HOLIDAY: 'Holiday',
  }.freeze

  MODES = {
    DO: 'DO',
    LG: 'LG'
  }.freeze

  ERRORS = {
    INVALID_DAY_NAME: 'Invalid day name: %s',
    INVALID_CONFIG: 'Invalid configuration: %s',
  }.freeze
end
