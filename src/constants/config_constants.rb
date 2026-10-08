module ConfigConstants
  KEYS = {
    TASKS: 'tasks_config',
    TASK_TEMPLATES: 'task_templates_config',
    LG_TEMPLATES: 'lg_templates_config',
    TAG_ORDER: 'tag_order_config',
    LG_TEMPLATE_BASE: 'base',
    LG_TEMPLATE_WEEKDAY: 'weekday',
    LG_TEMPLATE_WEEKEND: 'weekend',
    TEMPLATE: 'template',
    TEMPLATE_VARIABLES: 'template_variables',
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
    BIRTH_YEAR: 'birth_year',
  }.freeze

  TAG_ORDER_MARKER = '~~OTHER~~'.freeze

  # Internal key stamped on a task config so attach can record the owning task on the day.
  TASK_SOURCE_KEY = :__task_name__

  PLACEHOLDERS = {
    TEMPLATE_START: '{{',
    TEMPLATE_END: '}}',
    CONTENT: '{{CONTENT}}',
    AGE: '{{AGE}}'
  }.freeze

  BIRTH_YEAR_METHODS = {
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
    FILE_NOT_FOUND: 'File not found: %s'
  }.freeze
end
