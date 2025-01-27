module TestConstants
  CONFIG_FILES = {
    TEST_PATH: './test/test_config.yml',
    BLANK_PATH: './test/blank_config.yml',
    FAKE_PATH: './test/fake_config.yml',
  }.freeze

  OUTPUT = {
    DIRECTORY: './_out_test',
    FILE_2020: 'DO_2020.md',
  }.freeze

  KEYS = {
    DIMENSIONAL_1: '1_Dimensional',
    DIMENSIONAL_2: '2_Dimensional',
    DIMENSIONAL_3: '3_Dimensional',
    DIMENSIONAL_1_DOUBLE: '1_Dimensional_Double',
    DIMENSIONAL_2_MIXED: '2_Dimensional_Mixed',
    DIMENSIONAL_3_SIBLINGS_LEAF: '3_Dimensional_Leaf_Siblings',
    DIMENSIONAL_3_SIBLINGS_INTERNAL: '3_Dimensional_Internal_Siblings',
    BIRTHDAY_PERSON: 'Birthday_Person',
  }.freeze

  HOLIDAYS = {
    FIRST_DAY: 'First_Day',
    NTH_XDAY: 'Nth_XDay',
    LAST_XDAY: 'Last_XDay',
    LAST_DAY: 'Last_Day',
    LAST_DAY_IN_JANUARY: 'Last_Day_In_January',
    LAST_THURDAY_IN_JANUARY: 'Last_Thursday_In_January',
    BIRTHDAY_PERSON: 'Birthday_Person',
  }.freeze
end
