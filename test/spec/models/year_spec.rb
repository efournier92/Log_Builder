require './src/models/year'
require './src/models/day'
require './test/constants/test_constants'
require 'date'

describe Year do
  def build_year(year)
    Year.new(year, TestConstants::CONFIG_FILES[:BLANK_PATH])
  end

  def day_dates(do_year)
    do_year.days.map { |day| Date.new(day.year, day.month, day.month_day) }
  end

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

  describe '#first_monday' do
    it 'returns the raw offset with 0 for a Monday January 1' do
      expect(build_year(2024).first_monday).to eq(0)
    end

    it 'returns the offset for other weekdays' do
      expect(build_year(2020).first_monday).to eq(2)
      expect(build_year(2023).first_monday).to eq(6)
    end
  end

  describe '#days' do
    it 'covers exactly the boundary weeks for 2020' do
      do_year = build_year(2020)
      dates = day_dates(do_year)

      expect(do_year.days.first.name).to eq('Monday')
      expect(dates.first).to eq(Date.new(2019, 12, 30))
      expect(do_year.days.last.name).to eq('Sunday')
      expect(dates.last).to eq(Date.new(2021, 1, 3))
      expect(do_year.days.length).to eq(371)
    end

    it 'starts on January 1 when January 1 is a Monday' do
      dates = day_dates(build_year(2024))

      expect(dates.first).to eq(Date.new(2024, 1, 1))
      expect(dates.none? { |date| date.year == 2023 }).to be true
      expect(dates.last).to eq(Date.new(2025, 1, 5))
      expect(dates.length).to eq(371)
    end

    it 'ends on December 31 when December 31 is a Sunday' do
      dates = day_dates(build_year(2023))

      expect(dates.first).to eq(Date.new(2022, 12, 26))
      expect(dates.last).to eq(Date.new(2023, 12, 31))
      expect(dates.length).to eq(371)
    end

    it 'keeps 54 weeks for a leap year that begins on a Sunday' do
      do_year = build_year(2012)
      dates = day_dates(do_year)

      expect(dates.first).to eq(Date.new(2011, 12, 26))
      expect(dates.last).to eq(Date.new(2013, 1, 6))
      expect(do_year.days.length).to eq(378)
      expect(do_year.days.first.name).to eq('Monday')
      expect(do_year.days.last.name).to eq('Sunday')
    end

    it 'applies the century leap rules' do
      expect(build_year(1900).leap_year?).to be false
      expect(build_year(2000).leap_year?).to be true
      expect(build_year(2100).leap_year?).to be false
    end

    it 'builds whole Monday-to-Sunday weeks for 2000' do
      dates = day_dates(build_year(2000))

      expect(dates.length % 7).to eq(0)
      expect(dates.first.wday).to eq(1)
      expect(dates.last.wday).to eq(0)
      expect([371, 378]).to include(dates.length)
    end

    it 'includes every day of 2020 exactly once' do
      target_days = day_dates(build_year(2020)).select { |date| date.year == 2020 }

      expect(target_days.length).to eq(366)
      (Date.new(2020, 1, 1)..Date.new(2020, 12, 31)).each do |date|
        expect(target_days.count(date)).to eq(1)
      end
    end

    it 'does not include days outside the boundary weeks' do
      expect(day_dates(build_year(2020))).to_not include(Date.new(2021, 1, 4))
      expect(day_dates(build_year(2024))).to_not include(Date.new(2023, 12, 31))
      expect(day_dates(build_year(2023))).to_not include(Date.new(2024, 1, 1))
    end

    it 'matches the Monday-start weeks that intersect each year from 1900 to 2100' do
      (1900..2100).each do |year|
        do_year = Year.new(year, TestConstants::CONFIG_FILES[:BLANK_PATH])
        days = do_year.days
        jan1 = Date.new(year, 1, 1)
        dec31 = Date.new(year, 12, 31)
        expected_start = jan1 - ((jan1.wday - 1) % 7)
        expected_end = dec31 + ((7 - dec31.wday) % 7)

        expect(days.length % 7).to eq(0)
        expect(Date.new(days.first.year, days.first.month, days.first.month_day)).to eq(expected_start)
        expect(Date.new(days.last.year, days.last.month, days.last.month_day)).to eq(expected_end)
      end
    end
  end
end
