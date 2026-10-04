require './test/constants/test_constants'
require './src/constants/config_constants'
require './src/constants/app_constants'
require './src/services/add_task_service'
require './src/models/year'

def get_day_from_year(do_year, year, month, month_day)
  do_year.days.each do |day|
    return day if day.year == year && day.month == month && day.month_day == month_day
  end
end

describe AddTaskService do
  before :each do
    @service = AddTaskService.new
    @year = 2020
    @do_year = Year.new(@year, TestConstants::CONFIG_FILES[:BLANK_PATH])
  end

  describe '#to_each_day' do
    it 'raises an error for an invalid day name' do
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'InvalidDay',
        ConfigConstants::KEYS[:TAG] => 'Test_Tag'
      }

      expect { @service.to_each_day(@do_year, config) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_DAY_NAME], config[ConfigConstants::KEYS[:DAY_NAME]])
      )
    end

    it 'adds a configured tag to every day' do
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'Monday',
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_each_day(@do_year, config)

      do_year.days.each do |day|
        expect(day.tasks).to include(tag)
      end
    end
  end

  describe '#to_specific_date' do
    it 'adds a configured tag to January 1st' do
      month = 1
      month_day = 1
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:MONTH] => month,
        ConfigConstants::KEYS[:DAY] => month_day,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_specific_date(@do_year, config)
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end
  end

  describe '#to_nth_xday_in_month' do
    it 'adds a configured tag to the 2nd Tuesday in January' do
      month = 1
      nth_day = 2
      day_name = 'Tuesday'
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:MONTH] => month,
        ConfigConstants::KEYS[:NTH_DAY] => nth_day,
        ConfigConstants::KEYS[:DAY_NAME] => day_name,
        ConfigConstants::KEYS[:TAG] => tag
      }

      month_day = 14
      do_year = @service.to_nth_xday_in_month(@do_year, config)
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end

    it 'adds a configured tag to the 3rd Wednesday in May' do
      month = 5
      nth_day = 3
      day_name = 'Wednesday'
      tag = 'Test_Tag'
      month_day = 20
      config = {
        ConfigConstants::KEYS[:MONTH] => month,
        ConfigConstants::KEYS[:NTH_DAY] => nth_day,
        ConfigConstants::KEYS[:DAY_NAME] => day_name,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_xday_in_month(@do_year, config)
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end

    it 'raises an error for an invalid day name' do
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'InvalidDay',
        ConfigConstants::KEYS[:MONTH] => 1,
        ConfigConstants::KEYS[:NTH_DAY] => 1,
        ConfigConstants::KEYS[:TAG] => 'Test_Tag'
      }

      expect { @service.to_nth_xday_in_month(@do_year, config) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_DAY_NAME], config[ConfigConstants::KEYS[:DAY_NAME]])
      )
    end
  end

  describe '#to_each_xday' do
    it 'raises an error for an invalid day name' do
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'InvalidDay',
        ConfigConstants::KEYS[:TAG] => 'Test_Tag'
      }

      expect { @service.to_each_xday(@do_year, config) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_DAY_NAME], config[ConfigConstants::KEYS[:DAY_NAME]])
      )
    end

    it 'adds a configured tag only to the matching days' do
      tag = 'Monday_Tag'
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'Monday',
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_each_xday(@do_year, config)

      monday = get_day_from_year(do_year, @year, 1, 6)
      tuesday = get_day_from_year(do_year, @year, 1, 7)

      expect(monday.tasks).to include(tag)
      expect(tuesday.tasks).to_not include(tag)
    end
  end

  describe '#to_nth_xday_in_each_month' do
    it 'adds a configured tag to the 3rd Wednesday in each month' do
      nth_day = 3
      day_name = 'Wednesday'
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => nth_day,
        ConfigConstants::KEYS[:DAY_NAME] => day_name,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_xday_in_each_month(@do_year, config)

      month = 1
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 2
      month_day = 19
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 3
      month_day = 18
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 4
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 5
      month_day = 20
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 6
      month_day = 17
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 7
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 8
      month_day = 19
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 9
      month_day = 16
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 10
      month_day = 21
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 11
      month_day = 18
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 12
      month_day = 16
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)
    end

    it 'adds a configured tag to the 3rd Wednesday in each even month' do
      nth_day = 3
      day_name = 'Wednesday'
      tag = 'Even_Month_Task'
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => nth_day,
        ConfigConstants::KEYS[:DAY_NAME] => day_name,
        ConfigConstants::KEYS[:EVEN_ONLY?] => true,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_xday_in_each_month(@do_year, config)

      month = 1
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 2
      month_day = 19
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 3
      month_day = 18
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 4
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 5
      month_day = 20
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 6
      month_day = 17
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 7
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 8
      month_day = 19
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 9
      month_day = 16
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 10
      month_day = 21
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 11
      month_day = 18
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 12
      month_day = 16
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)
    end

    it 'adds a configured tag to the 3rd Wednesday in each odd month' do
      nth_day = 3
      day_name = 'Wednesday'
      tag = 'Odd_Month_Task'
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => nth_day,
        ConfigConstants::KEYS[:DAY_NAME] => day_name,
        ConfigConstants::KEYS[:ODD_ONLY?] => true,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_xday_in_each_month(@do_year, config)

      month = 1
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 2
      month_day = 19
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 3
      month_day = 18
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 4
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 5
      month_day = 20
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 6
      month_day = 17
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 7
      month_day = 15
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 8
      month_day = 19
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 9
      month_day = 16
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 10
      month_day = 21
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)

      month = 11
      month_day = 18
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 12
      month_day = 16
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to_not include(tag)
    end

    it 'mutates the passed config by setting is_each' do
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => 3,
        ConfigConstants::KEYS[:DAY_NAME] => 'Wednesday',
        ConfigConstants::KEYS[:TAG] => 'Test_Tag'
      }

      @service.to_nth_xday_in_each_month(@do_year, config)

      expect(config[ConfigConstants::KEYS[:IS_EACH?]]).to be true
    end
  end

  describe '#to_last_xday_in_month' do
    it 'adds a configured tag to the last Friday in January' do
      month = 1
      day_name = 'Friday'
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:MONTH] => month,
        ConfigConstants::KEYS[:DAY_NAME] => day_name,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_last_xday_in_month(@do_year, config)
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end

    it 'does not validate the day name unlike #to_nth_xday_in_month' do
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:MONTH] => 1,
        ConfigConstants::KEYS[:DAY_NAME] => 'InvalidDay',
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_last_xday_in_month(@do_year, config)

      do_year.days.each do |day|
        expect(day.tasks).to_not include(tag)
      end
    end
  end

  describe '#to_last_xday_in_each_month' do
    it 'adds a configured tag to the last Friday in each month' do
      day_name = 'Friday'
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => day_name,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_last_xday_in_each_month(@do_year, config)

      month = 1
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 2
      month_day = 28
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 3
      month_day = 27
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 4
      month_day = 24
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 5
      month_day = 29
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 6
      month_day = 26
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 7
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 8
      month_day = 28
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 9
      month_day = 25
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 10
      month_day = 30
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 11
      month_day = 27
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 12
      month_day = 25
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)
    end
  end

  describe '#to_last_day_in_month' do
    it 'adds a configured tag to the last day in January' do
      month = 1
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:MONTH] => month,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_last_day_in_month(@do_year, config)
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end

    it 'adds a configured tag to the last day in December' do
      month = 12
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:MONTH] => month,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_last_day_in_month(@do_year, config)
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end
  end

  describe '#to_last_day_in_each_month' do
    it 'adds a configured tag to the last day in each month' do
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_last_day_in_each_month(@do_year, config)

      month = 1
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 2
      month_day = 29
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 3
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 4
      month_day = 30
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 5
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 6
      month_day = 30
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 7
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 8
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 9
      month_day = 30
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 10
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 11
      month_day = 30
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 12
      month_day = 31
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)
    end
  end

  describe '#to_nth_day_in_each_month' do
    it 'adds a configured tag to the 15th day of each month' do
      tag = 'Monthly_Task'
      day_number = 15
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => day_number,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_day_in_each_month(@do_year, config)

      AppConstants::LISTS[:ALL_MONTHS].each do |month_number|
        day = get_day_from_year(do_year, @year, month_number, day_number)
        expect(day.tasks).to include(tag)
      end
    end

    it 'adds a configured tag to the 17th day of each odd month' do
      tag = 'Odd_Monthly_Task'
      day_number = 17
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => day_number,
        ConfigConstants::KEYS[:ODD_ONLY?] => true,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_day_in_each_month(@do_year, config)

      AppConstants::LISTS[:ODD_MONTHS].each do |month_number|
        day = get_day_from_year(do_year, @year, month_number, day_number)
        expect(day.tasks).to include(tag)
      end

      AppConstants::LISTS[:EVEN_MONTHS].each do |month_number|
        day = get_day_from_year(do_year, @year, month_number, day_number)
        expect(day.tasks).to_not include(tag)
      end
    end

    it 'adds a configured tag to the 18th day of each even month' do
      tag = 'Even_Monthly_Task'
      day_number = 18
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => day_number,
        ConfigConstants::KEYS[:EVEN_ONLY?] => true,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_day_in_each_month(@do_year, config)

      AppConstants::LISTS[:EVEN_MONTHS].each do |month_number|
        day = get_day_from_year(do_year, @year, month_number, day_number)
        expect(day.tasks).to include(tag)
      end

      AppConstants::LISTS[:ODD_MONTHS].each do |month_number|
        day = get_day_from_year(do_year, @year, month_number, day_number)
        expect(day.tasks).to_not include(tag)
      end
    end

    it 'raises an error if NTH_DAY is not provided' do
      config = {
        ConfigConstants::KEYS[:TAG] => 'Test_Tag'
      }

      expect { @service.to_nth_day_in_each_month(@do_year, config) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'NTH_DAY is required')
      )
    end
  end

  describe '#to_xday_every_n_weeks' do
    it 'adds a configured tag to the 2nd Wednesday of the year' do
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'Wednesday',
        ConfigConstants::KEYS[:N_WEEKS] => 2,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_xday_every_n_weeks(@do_year, config)
      month = 1
      month_day = 8
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end

    it 'adds a configured tag to the 2nd Tuesday of the year' do
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'Tuesday',
        ConfigConstants::KEYS[:N_WEEKS] => 2,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_xday_every_n_weeks(@do_year, config)

      month = 1
      month_day = 14
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 1
      month_day = 28
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 2
      month_day = 11
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 3
      month_day = 24
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 4
      month_day = 7
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 9
      month_day = 8
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 11
      month_day = 17
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)

      month = 12
      month_day = 29
      day = get_day_from_year(do_year, @year, month, month_day)
      expect(day.tasks).to include(tag)
    end

    it 'raises an error for an invalid day name' do
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'InvalidDay',
        ConfigConstants::KEYS[:N_WEEKS] => 2,
        ConfigConstants::KEYS[:TAG] => 'Test_Tag'
      }

      expect { @service.to_xday_every_n_weeks(@do_year, config) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_DAY_NAME], config[ConfigConstants::KEYS[:DAY_NAME]])
      )
    end

    it 'resets the week counter when the days span a year boundary' do
      tag = 'Test_Tag'
      config = {
        ConfigConstants::KEYS[:DAY_NAME] => 'Monday',
        ConfigConstants::KEYS[:N_WEEKS] => 2,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_xday_every_n_weeks(@do_year, config)

      first_monday = get_day_from_year(do_year, 2019, 12, 30)
      boundary_monday = get_day_from_year(do_year, 2020, 1, 6)
      next_monday = get_day_from_year(do_year, 2020, 1, 13)

      expect(first_monday.tasks).to_not include(tag)
      expect(boundary_monday.tasks).to_not include(tag)
      expect(next_monday.tasks).to include(tag)
    end
  end

  describe '#to_easter' do
    it 'adds the configured tag to the correct Easter date' do
      tag = 'Easter'
      config = {
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_easter(@do_year, config)
      month = 4
      month_day = 12
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end
  end

  describe '#to_good_friday' do
    it 'adds the configured tag to the correct Good Friday date' do
      tag = 'Good Friday'
      config = {
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_good_friday(@do_year, config)
      month = 4
      month_day = 10
      day = get_day_from_year(do_year, @year, month, month_day)

      expect(day.tasks).to include(tag)
    end
  end

  describe '#get_good_friday_month' do
    it 'returns the previous month when Easter falls on the 1st or 2nd' do
      expect(@service.send(:get_good_friday_month, 2, 3)).to eq(2)
      expect(@service.send(:get_good_friday_month, 1, 4)).to eq(3)
    end

    it 'returns the Easter month for a later Easter day' do
      expect(@service.send(:get_good_friday_month, 3, 3)).to eq(3)
    end
  end

  describe '#get_good_friday_day' do
    it 'returns the last day of the month when Easter is on the 2nd' do
      expect(@service.send(:get_good_friday_day, 31, 2)).to eq(31)
    end

    it 'returns one day before the last day when Easter is on the 1st' do
      expect(@service.send(:get_good_friday_day, 31, 1)).to eq(30)
    end

    it 'returns two days before Easter otherwise' do
      expect(@service.send(:get_good_friday_day, 31, 5)).to eq(3)
    end
  end

  describe '#to_nth_day_in_each_quarter' do
    it 'only adds the configured tag to each quarter month' do
      tag = 'Quarterly_Task'
      nth_day = 4
      config = {
        ConfigConstants::KEYS[:NTH_DAY] => nth_day,
        ConfigConstants::KEYS[:TAG] => tag
      }

      do_year = @service.to_nth_day_in_each_quarter(@do_year, config)

      AppConstants::LISTS[:QUARTER_MONTHS].each do |month|
        month_day = nth_day
        day = get_day_from_year(do_year, @year, month, month_day)
        expect(day.tasks).to include(tag)
      end

      AppConstants::LISTS[:NON_QUARTER_MONTHS].each do |month|
        month_day = nth_day
        day = get_day_from_year(do_year, @year, month, month_day)
        expect(day.tasks).to_not include(tag)
      end
    end

    it 'raises an error if NTH_DAY is not provided' do
      config = {
        ConfigConstants::KEYS[:TAG] => 'Test_Tag'
      }

      expect { @service.to_nth_day_in_each_quarter(@do_year, config) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'NTH_DAY is required')
      )
    end
  end
end
