require './src/models/year'
require './src/models/day'
require './test/constants/test_constants'

describe Year do
  context 'given a year' do
    it 'returns an object' do
      expect(Year.new(2020, TestConstants::CONFIG_FILES[:TEST_PATH])).to be_an_instance_of(Year)
    end
  end

  describe '#leap_year?' do
    it 'returns true for 2000' do
      expect(Year.new(2000, TestConstants::CONFIG_FILES[:BLANK_PATH]).leap_year?).to be true
    end

    it 'returns false for 1900' do
      expect(Year.new(1900, TestConstants::CONFIG_FILES[:BLANK_PATH]).leap_year?).to be false
    end

    it 'returns false for 2021' do
      expect(Year.new(2021, TestConstants::CONFIG_FILES[:BLANK_PATH]).leap_year?).to be false
    end

    it 'returns true for 2020' do
      expect(Year.new(2020, TestConstants::CONFIG_FILES[:BLANK_PATH]).leap_year?).to be true
    end
  end

  describe '#get_days_in_months' do
    it 'returns 29 for February in a leap year' do
      do_year = Year.new(2020, TestConstants::CONFIG_FILES[:BLANK_PATH])

      expect(do_year.get_days_in_months[1]).to eq(29)
    end

    it 'returns 28 for February otherwise' do
      do_year = Year.new(2021, TestConstants::CONFIG_FILES[:BLANK_PATH])

      expect(do_year.get_days_in_months[1]).to eq(28)
    end
  end

  describe '.valid_day_name?' do
    it 'returns true for a valid day name' do
      expect(Year.valid_day_name?('Monday')).to be true
    end

    it 'returns false for an invalid day name' do
      expect(Year.valid_day_name?('InvalidDay')).to be false
    end
  end

  describe '#add_next_week' do
    it 'rolls the month and year over the constructed range' do
      do_year = Year.new(2020, TestConstants::CONFIG_FILES[:BLANK_PATH])

      expect(do_year.days.first.month).to eq(12)
      expect(do_year.days.first.year).to eq(2019)
      expect(do_year.days.last.month).to eq(1)
      expect(do_year.days.last.year).to eq(2021)
      expect(do_year.days.length).to eq(378)
    end
  end

  describe '#first_monday' do
    it 'lands the first day on a Monday when the correction branch is used' do
      do_year = Year.new(2024, TestConstants::CONFIG_FILES[:BLANK_PATH])

      expect(do_year.days.first.name).to eq('Monday')
      expect(do_year.days.first.month_day).to eq(25)
    end

    it 'lands the first day on a Monday for other weekdays' do
      do_year = Year.new(2020, TestConstants::CONFIG_FILES[:BLANK_PATH])
      expect(do_year.days.first.name).to eq('Monday')

      another_year = Year.new(2021, TestConstants::CONFIG_FILES[:BLANK_PATH])
      expect(another_year.days.first.name).to eq('Monday')
    end
  end
end
