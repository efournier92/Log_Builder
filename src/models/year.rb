require_relative './day'
require_relative '../services/configured_tasks_service'
require 'pry-byebug'

class Year
  attr_accessor :days
  attr_reader :year_number, :days_in_months, :config_file

  WEEKEND_DAY_NAMES = %w[Saturday Sunday].freeze
  WEEKDAY_DAY_NAMES = %w[Monday Tuesday Wednesday Thursday Friday].freeze
  DAY_NAMES = WEEKDAY_DAY_NAMES + WEEKEND_DAY_NAMES

  def initialize(year_number, config_file)
    @year_number = year_number
    @year_counter = year_number
    @config_file = config_file

    initialize_values

    54.times do
      add_next_week
    end

    add_configured_tasks
  end

  def initialize_values
    @days = []
    @day_counter = first_monday
    @month_counter = 12
    @week_counter = 1
    @day_counter = 31 - (7 - @day_counter)
    @year_counter -= 1
    @day_in_month_counter = @day_counter
    @days_in_months = get_days_in_months
  end

  def add_next_week
    DAY_NAMES.each do |day_name|
      day = Day.new(day_name, '', @year_counter, @month_counter, @day_in_month_counter)
      @days.push(day)
      @day_in_month_counter += 1
      @week_counter += 1
      @day_counter += 1
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

  def first_monday
    years_since = @year_number - 1
    leap_years = years_since / 4
    century_years = years_since / 100
    four_century_years = years_since / 400

    total_leap_years = leap_years - century_years + four_century_years
    total_precesion = years_since + total_leap_years
    @day_counter = total_precesion % 7

    first_monday = 8 - @day_counter

    first_monday -= 7 if first_monday > 7
    first_monday
  end

  def add_configured_tasks
    add_task_service = ConfiguredTasksService.new
    add_task_service.add_configured_tasks(self)
  end
end
