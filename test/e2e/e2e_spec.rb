require './src/services/file_parser_service'
require './test/constants/test_constants'
require 'pathname'

def create_log_file(config_file, print_type, print_year, print_month, output_dir)
  `ruby ./src/run.rb '#{config_file}' '#{print_type}' '#{print_year}' '#{print_month}' '#{output_dir}'`
end

context 'User sketches a full-year DO file' do
  before :all do
    @output_dir = TestConstants::OUTPUT[:DIRECTORY]
    output_year = 2020
    output_file_name = "#{@output_dir}/DO_#{output_year}.md"
    @output_file_path = Pathname.new(output_file_name)

    create_log_file(TestConstants::CONFIG_FILES[:TEST_PATH], 'DO', output_year, 'ALL', @output_dir)

    file_contents = IO.read(@output_file_path)

    file_parser = FileParser.new
    @do_hash = file_parser.get_date_hash_from_do_file(file_contents)
  end

  after :all do
    `rm -rf #{@output_dir}`
  end

  context 'when creating a whole year' do
    it 'creates the log file' do
      expect(@output_file_path).to exist
    end

    it 'adds dates to the log file' do
      expect(@do_hash['2020-01-01']).to_not be(nil)
    end
  end

  context 'given we configure periodic configured tasks for the whole 2020 year' do
    it 'adds a configured tasks to a specific date' do
      date = '2020-01-01'
      expect(@do_hash[date]).to include('First_Day')
    end

    it 'adds a configured tasks to the 2nd Tuesday in a specific month' do
      date = '2020-01-14'
      expect(@do_hash[date]).to include('Nth_XDay')
    end

    it 'adds a configured tasks to the 2nd Monday in each month' do
      january_date   = '2020-01-13'
      february_date  = '2020-02-10'
      march_date     = '2020-03-09'
      april_date     = '2020-04-13'
      may_date       = '2020-05-11'
      june_date      = '2020-06-08'
      july_date      = '2020-07-13'
      august_date    = '2020-08-10'
      september_date = '2020-09-14'
      october_date   = '2020-10-12'
      november_date  = '2020-11-09'
      december_date  = '2020-12-14'

      expect(@do_hash[january_date]).to include('Nth_Each_XDay')
      expect(@do_hash[february_date]).to include('Nth_Each_XDay')
      expect(@do_hash[march_date]).to include('Nth_Each_XDay')
      expect(@do_hash[april_date]).to include('Nth_Each_XDay')
      expect(@do_hash[may_date]).to include('Nth_Each_XDay')
      expect(@do_hash[june_date]).to include('Nth_Each_XDay')
      expect(@do_hash[july_date]).to include('Nth_Each_XDay')
      expect(@do_hash[august_date]).to include('Nth_Each_XDay')
      expect(@do_hash[september_date]).to include('Nth_Each_XDay')
      expect(@do_hash[october_date]).to include('Nth_Each_XDay')
      expect(@do_hash[november_date]).to include('Nth_Each_XDay')
      expect(@do_hash[december_date]).to include('Nth_Each_XDay')
    end

    it 'adds a configured task to the last Tuesday in September' do
      september_date = '2020-09-29'

      expect(@do_hash[september_date]).to include('Last_XDay')
    end

    it 'adds a configured task to the last Friday in each month' do
      january_date   = '2020-01-31'
      february_date  = '2020-02-28'
      march_date     = '2020-03-27'
      april_date     = '2020-04-24'
      may_date       = '2020-05-29'
      june_date      = '2020-06-26'
      july_date      = '2020-07-31'
      august_date    = '2020-08-28'
      september_date = '2020-09-25'
      october_date   = '2020-10-30'
      november_date  = '2020-11-27'
      december_date  = '2020-12-25'

      expect(@do_hash[january_date]).to include('Last_Each_XDay')
      expect(@do_hash[february_date]).to include('Last_Each_XDay')
      expect(@do_hash[march_date]).to include('Last_Each_XDay')
      expect(@do_hash[april_date]).to include('Last_Each_XDay')
      expect(@do_hash[may_date]).to include('Last_Each_XDay')
      expect(@do_hash[june_date]).to include('Last_Each_XDay')
      expect(@do_hash[july_date]).to include('Last_Each_XDay')
      expect(@do_hash[august_date]).to include('Last_Each_XDay')
      expect(@do_hash[september_date]).to include('Last_Each_XDay')
      expect(@do_hash[october_date]).to include('Last_Each_XDay')
      expect(@do_hash[november_date]).to include('Last_Each_XDay')
      expect(@do_hash[december_date]).to include('Last_Each_XDay')
    end

    it 'adds a configured tasks to the last day in November' do
      date = '2020-11-30'
      expect(@do_hash[date]).to include('Last_Day')
    end

    it 'adds Easter to the correct date' do
      date = '2020-04-12'
      expect(@do_hash[date]).to include("Holiday(\n  Easter,\n),")
    end

    it 'adds Good Friday' do
      date = '2020-04-10'
      expect(@do_hash[date]).to include("Holiday(\n  Good_Friday,\n),")
    end

    # it 'adds a birthday' do
    #   date = '2020-07-04'
    #   expected = "Birthday(\n  Name(\n    Person(\n      Name(UncleSam,),\n    ),\n  ),"
    #   expected += "\n  Contact(\n    Contact(000-000-0000,),\n  ),\n),"
    #   expect(@do_hash[date]).to include(expected)
    # end
  end

  context 'given same-day root tag collisions' do
    it 'keeps a day with no collision byte-identical' do
      expect(@do_hash['2020-01-04']).to eq("\n\n```text\nTask_Name(\n  Task_Value,\n),")
    end

    it 'renders a single Level_1 on a Tuesday' do
      expect(@do_hash['2020-01-07'].scan('Level_1,').size).to eq(1)
    end

    it 'keeps the Thursday leaf inside the internal Level_1' do
      expected = "Level_1(\n  Level_1,\n  Level_2(\n    Level_3,\n  ),\n),"
      expect(@do_hash['2020-01-02']).to include(expected)
    end

    it 'merges the two January 31st Holiday tags into one' do
      expect(@do_hash['2020-01-31'].scan('Holiday(').size).to eq(1)
      expect(@do_hash['2020-01-31']).to include("Holiday(\n  Last_Each_XDay,\n  Last_Day_In_January,\n),")
    end
  end
end

context 'User merges same-day root tags from a collision config' do
  before :all do
    @output_dir = TestConstants::OUTPUT[:DIRECTORY]
    output_year = 2020
    output_file_name = "#{@output_dir}/DO_#{output_year}.md"
    @output_file_path = Pathname.new(output_file_name)

    create_log_file(TestConstants::CONFIG_FILES[:COLLISION_PATH], 'DO', output_year, 'ALL', @output_dir)

    file_contents = IO.read(@output_file_path)

    file_parser = FileParser.new
    @do_hash = file_parser.get_date_hash_from_do_file(file_contents)
  end

  after :all do
    `rm -rf #{@output_dir}`
  end

  it 'merges the four Body contributions into one root' do
    expect(@do_hash['2020-01-01'].scan('Body(').size).to eq(1)
  end

  it 'renders the union of Ears children with Drops_Apply deduped' do
    expected = "Body(\n  Ears(\n    Drops_Apply,\n    Camera_Wax_Remove,\n  ),\n" \
               "  Vitamins_Take(\n    Pills,\n  ),\n),"
    expect(@do_hash['2020-01-01']).to include(expected)
    expect(@do_hash['2020-01-01'].scan('Drops_Apply').size).to eq(1)
  end

  it 'places the merged Body above Zeta in the bottom slot' do
    expected = "\n\n```text\nBody(\n  Ears(\n    Drops_Apply,\n    Camera_Wax_Remove,\n  ),\n" \
               "  Vitamins_Take(\n    Pills,\n  ),\n),\nZeta,"
    expect(@do_hash['2020-01-01']).to eq(expected)
  end
end

context 'User sketches a full-year LG file' do
  before :all do
    @output_dir = TestConstants::OUTPUT[:DIRECTORY]
    output_year = 2020
    output_file_name = "#{@output_dir}/LG_#{output_year}.md"
    @output_file_path = Pathname.new(output_file_name)

    create_log_file(TestConstants::CONFIG_FILES[:TEST_PATH], 'LG', output_year, 'ALL', @output_dir)

    file_contents = IO.read(output_file_name)

    file_parser = FileParser.new
    @do_hash = file_parser.get_date_hash_from_lg_file(file_contents)
  end

  after :all do
    `rm -rf #{@output_dir}`
  end

  context 'when creating a LG file' do
    it 'creates the file' do
      expect(@output_file_path).to exist
    end

    context 'when testing whitespace inclusion' do
      it 'includes expected whitespace breaks for weekdays' do
        expect(@do_hash['## 2020-01-02 | Thursday']).to eq(
          "### Do\n\n```text\n```\n\n### Notes\n\n#### Yesterday\n\n#### Today"
        )
      end

      it 'includes expected whitespace breaks for weekends' do
        expect(@do_hash['## 2020-01-04 | Saturday']).to eq("### Do\n\n```text\n```")
      end

      it 'includes expected whitespace breaks for mondays' do
        expect(@do_hash['## 2020-07-06 | Monday']).to eq(
          "### Do\n\n```text\n```\n\n### Notes\n\n#### Last Friday\n\n#### Today"
        )
      end

      it 'includes expected whitespace breaks for fridays' do
        expect(@do_hash['## 2020-07-03 | Friday']).to eq(
          "### Do\n\n```text\n```\n\n### Notes\n\n#### Yesterday\n\n#### Today\n\n" \
          "### Notes\n\n#### Last Friday\n\n#### Today"
        )
      end
    end

    it 'adds expected dates to the log file' do
      expect(@do_hash['## 2020-01-01 | Wednesday']).to_not be(nil)
      expect(@do_hash['## 2020-07-04 | Saturday']).to_not be(nil)
      expect(@do_hash['## 2020-12-31 | Thursday']).to_not be(nil)
    end

    it 'populates weekdays with the weekday template' do
      date = '## 2020-01-01 | Wednesday'
      expect(@do_hash[date]).to include('### Do')
      expect(@do_hash[date]).to include('### Notes')
      expect(@do_hash[date]).to include('#### Yesterday')
      expect(@do_hash[date]).to include('#### Today')
    end

    it 'populates weekends with the weekend template' do
      date = '## 2020-07-04 | Saturday'
      expect(@do_hash[date]).to include('### Do')
      expect(@do_hash[date]).to_not include('### Notes')
      expect(@do_hash[date]).to_not include('#### Yesterday')
      expect(@do_hash[date]).to_not include('#### Today')
    end

    it 'overrides the weekday template with the configured monday template' do
      date = '## 2020-07-06 | Monday'
      expect(@do_hash[date]).to include('### Do')
      expect(@do_hash[date]).to include('### Notes')
      expect(@do_hash[date]).to_not include('#### Yesterday')
      expect(@do_hash[date]).to include('#### Last Friday')
      expect(@do_hash[date]).to include('#### Today')
    end
  end
end
