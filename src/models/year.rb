require_relative './day'
require_relative '../services/configured_tasks_service'

class Year
  attr_accessor :days
  attr_reader :year_number, :days_in_months, :config_file

  WEEKEND_DAY_NAMES = %w[Saturday Sunday].freeze
  WEEKDAY_DAY_NAMES = %w[Monday Tuesday Wednesday Thursday Friday].freeze
  DAY_NAMES = WEEKDAY_DAY_NAMES + WEEKEND_DAY_NAMES

  def self.valid_day_name?(day_name)
    DAY_NAMES.include?(day_name)
  end

  def initialize(year_number, config_file)
    @year_number = year_number
    @year_counter = year_number
    @config_file = config_file

    initialize_values

    week_count.times do
      add_next_week
    end

    add_configured_tasks
  end

  def initialize_values
    @days = []
    @days_in_months = get_days_in_months
    @day_offset = first_monday
    if @day_offset.zero?
      @year_counter = @year_number
      @month_counter = 1
      @day_in_month_counter = 1
    else
      # Prior-year December day 32 - offset is the Monday opening the boundary week.
      @year_counter = @year_number - 1
      @month_counter = 12
      @day_in_month_counter = 32 - @day_offset
    end
  end

  def week_count
    days_in_year = leap_year? ? 366 : 365
    december_31_weekday = (@day_offset + days_in_year - 1) % 7
    # minimalist: pad December 31 out to its following Sunday, then count whole weeks.
    trailing_days = (6 - december_31_weekday) % 7
    (@day_offset + days_in_year + trailing_days) / 7
  end

  def add_next_week
    DAY_NAMES.each do |day_name|
      day = Day.new(day_name, '', @year_counter, @month_counter, @day_in_month_counter)
      @days.push(day)
      @day_in_month_counter += 1
      next unless @day_in_month_counter > @days_in_months[@month_counter - 1]

      @month_counter += 1
      if @month_counter == 13
        @month_counter = 1
        @year_counter += 1
      end
      @day_in_month_counter = 1
    end
  end

  def get_days_in_months # rubocop:disable Naming/AccessorMethodName
    days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    days[1] = 29 if leap_year?
    days
  end

  def leap_year?
    (@year_number % 4).zero? && !((@year_number % 100).zero? && @year_number % 400 != 0)
  end

  # minimalist: raw 0..6 offset from the week Monday back to January 1; no clamping.
  def first_monday
    years_since = @year_number - 1
    leap_years = years_since / 4
    century_years = years_since / 100
    four_century_years = years_since / 400

    total_leap_years = leap_years - century_years + four_century_years
    total_precession = years_since + total_leap_years
    total_precession % 7
  end

  def add_configured_tasks
    add_task_service = ConfiguredTasksService.new
    add_task_service.add_configured_tasks(self)
  end
end
