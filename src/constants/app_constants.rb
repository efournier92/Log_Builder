module AppConstants
  MODES = {
    DO: 'DO',
    LG: 'LG',
    ALL: 'ALL'
  }.freeze

  INPUT_PROMPTS = {
    MODE: "DO || LG\n>> ",
    YEAR: "Which Year?\n>> ",
    MONTH: "MONTH: [1-12] || ALL\n>> "
  }.freeze

  REGEX = {
    VALID_MONTH: /^([1-9]|1[0-2])$/
  }.freeze

  LISTS = {
    ALL_MONTHS: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    EVEN_MONTHS: [2, 4, 6, 8, 10, 12],
    ODD_MONTHS: [1, 3, 5, 7, 9, 11],
    QUARTER_MONTHS: [1, 4, 7, 10],
    NON_QUARTER_MONTHS: [2, 3, 5, 6, 8, 9, 11, 12]
  }.freeze

  ERROR_MESSAGES = {
    INVALID_CONFIG_FILE: 'Invalid config file. Exiting...'
  }.freeze
end
