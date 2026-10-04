require './src/services/configured_tasks_service'
require './src/models/year'
require './src/constants/config_constants'
require './test/constants/test_constants'

describe ConfiguredTasksService do
  before :each do
    @tag_service = ConfiguredTasksService.new
    @year = Year.new(2020, TestConstants::CONFIG_FILES[:TEST_PATH])
  end

  context 'given class construction' do
    describe '#add_configured_tasks' do
      it 'adds a tag based on a configured template to a specific date' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 1 }
        holiday_name = TestConstants::HOLIDAYS[:FIRST_DAY]

        expect(day.tasks).to include("Holiday(\n  #{holiday_name},\n),\n")
      end

      it 'adds a tag based on a configured template to the 2nd Tuesday in a month' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 14 }
        holiday_name = TestConstants::HOLIDAYS[:NTH_XDAY]

        expect(day.tasks).to include("Holiday(\n  #{holiday_name},\n),\n")
      end

      it 'adds a tag to the last Thursday in January' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 30 }
        holiday_name = TestConstants::HOLIDAYS[:LAST_THURDAY_IN_JANUARY]

        expect(day.tasks).to include("Holiday(\n  #{holiday_name},\n),\n")
      end

      it 'adds a tag to the last day in January' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 31 }
        holiday_name = TestConstants::HOLIDAYS[:LAST_DAY_IN_JANUARY]

        expect(day.tasks).to include("Holiday(\n  #{holiday_name},\n),\n")
      end

      it 'properly prints a multi-level birthday template' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 3 }

        expected_tag = "Birthday(\n  Name(PersonsName,),\n  Contact(000-000-0000,),\n),"
        expect(day.tasks).to include(expected_tag)
      end

      it 'properly prints a single-level task with no placeholders' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 4 }

        expected_tag = "Task_Name(\n  Task_Value,\n),\n"
        expect(day.tasks).to include(expected_tag)
      end

      it 'properly prints a 2-level task with no placeholders' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 5 }

        expected_tag = "Level_1(\n  Level_2a(Level_2a_Value,),\n  Level_2b(Level_2b_Value,),\n),"
        expect(day.tasks).to include(expected_tag)
      end

      it 'properly prints a multi-level task with no placeholders' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 6 }

        expected_tag = "Level_1(\n  Level_2a(\n    Level_3a,\n  ),\n  Level_2b(\n    Level_3b,\n  ),\n),"
        expect(day.tasks).to include(expected_tag)
      end

      it 'properly prints a single-level task template with placeholders' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 7 }

        expected_tag = "Task_Name(\n  Placeholder,\n),\n"
        expect(day.tasks).to include(expected_tag)
      end

      it 'properly prints a multi-level task with placeholders' do
        day = @year.days.find { |d| d.month == 1 && d.month_day == 8 }

        expected_tag = "Level_1(\n  Level_2a(\n    Placeholder_a,\n  ),\n  Level_2b(\n    Placeholder_b,\n  ),\n),"
        expect(day.tasks).to include(expected_tag)
      end

      it 'returns early when there are no configured tasks' do
        reader = double('ConfigReaderService', configured_tasks: nil)
        allow(ConfigReaderService).to receive(:new).and_return(reader)

        expect(@tag_service.add_configured_tasks(@year)).to be_nil
      end

      it 'adds a tag for a method that runs every n weeks' do
        task_config = {
          ConfigConstants::KEYS[:METHOD] => 'to_xday_every_n_weeks',
          ConfigConstants::KEYS[:TEMPLATE] => ConfigConstants::TEMPLATE_TYPES[:HOLIDAY],
          ConfigConstants::KEYS[:DAY_NAME] => 'Monday',
          ConfigConstants::KEYS[:N_WEEKS] => 2,
          ConfigConstants::KEYS[:TEMPLATE_VARIABLES] => [{ '{{CONTENT}}' => 'Every_2_Weeks' }],
        }
        reader = double('ConfigReaderService')
        allow(reader).to receive(:configured_tasks).and_return('Every_2_Weeks' => task_config)
        allow(reader).to receive(:configured_task_templates).and_return(
          ConfigConstants::TEMPLATE_TYPES[:HOLIDAY] => {
            ConfigConstants::TEMPLATE_TYPES[:HOLIDAY] => ['{{CONTENT}}'],
          }
        )
        allow(ConfigReaderService).to receive(:new).and_return(reader)

        @tag_service.add_configured_tasks(@year)

        day = @year.days.find { |d| d.month == 1 && d.month_day == 13 }
        expect(day.tasks).to include("Holiday(\n  Every_2_Weeks,\n),\n")
      end
    end
  end
end
