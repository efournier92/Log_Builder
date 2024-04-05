require './src/models/year'
require './src/constants/config_constants'
require './src/constants/app_constants'

class AddTaskService
  def to_specific_date(do_year, config)
    month = config[ConfigConstants::KEYS[:MONTH]]
    month_day = config[ConfigConstants::KEYS[:DAY]]
    new_tag = config[ConfigConstants::KEYS[:TAG]]
    is_each = config[ConfigConstants::KEYS[:IS_EACH?]]

    do_year.days.each do |day|
      day.tasks.prepend(new_tag) if (day.month == month || is_each) && day.month_day == month_day
    end
    do_year
  end

  def to_each_day(do_year, config)
    # TODO: Throw config error if invalid day name
    new_tag = config[ConfigConstants::KEYS[:TAG]]

    do_year.days.each do |day|
      day.tasks.prepend(new_tag)
    end
    do_year
  end

  def to_each_xday(do_year, config)
    # TODO: Throw config error if invalid day name
    day_name = config[ConfigConstants::KEYS[:DAY_NAME]]
    new_tag = config[ConfigConstants::KEYS[:TAG]]

    do_year.days.each do |day|
      day.tasks.prepend(new_tag) if day.name == day_name
    end
    do_year
  end

  def to_nth_xday_in_month(do_year, config)
    month = config[ConfigConstants::KEYS[:MONTH]]
    nth_day = config[ConfigConstants::KEYS[:NTH_DAY]]
    # TODO: Throw config error if invalid day name
    day_name = config[ConfigConstants::KEYS[:DAY_NAME]]
    new_tag = config[ConfigConstants::KEYS[:TAG]]
    is_each = config[ConfigConstants::KEYS[:IS_EACH?]]

    day_count = 0

    last_month = 0
    do_year.days.each do |day|
      if last_month != day.month
        last_month = day.month
        day_count = 0
      end

      next unless (is_each || day.month == month) && day.name == day_name

      day_count += 1
      day.tasks.prepend(new_tag) if day_count == nth_day
    end
    do_year
  end

  def to_nth_xday_in_each_month(do_year, config)
    config[ConfigConstants::KEYS[:IS_EACH?]] = true
    to_nth_xday_in_month(do_year, config)
  end

  def to_last_xday_in_month(do_year, config)
    month = config[ConfigConstants::KEYS[:MONTH]]
    day_name = config[ConfigConstants::KEYS[:DAY_NAME]]
    new_tag = config[ConfigConstants::KEYS[:TAG]]
    is_each = config[ConfigConstants::KEYS[:IS_EACH?]]

    do_year.days.each do |day|
      last_week_in_month_start_date = do_year.days_in_months[day.month - 1] - 6
      next unless (is_each || day.month == month) &&
                  day.name == day_name &&
                  day.month_day >= last_week_in_month_start_date

      day.tasks.prepend(new_tag)
    end
    do_year
  end

  def to_last_xday_in_each_month(do_year, config)
    config[ConfigConstants::KEYS[:IS_EACH?]] = true
    to_last_xday_in_month(do_year, config)
  end

  def to_last_day_in_month(do_year, config)
    month = config[ConfigConstants::KEYS[:MONTH]]
    config[ConfigConstants::KEYS[:DAY]] = do_year.days_in_months[month - 1]

    to_specific_date(do_year, config)
  end

  def to_last_day_in_each_month(do_year, config)
    do_year.days_in_months.each_with_index do |days_in_month, index|
      config[ConfigConstants::KEYS[:MONTH]] = index + 1
      config[ConfigConstants::KEYS[:DAY]] = days_in_month

      to_specific_date(do_year, config)
    end
    do_year
  end

  def to_nth_day_in_each_month(do_year, config)
    config[ConfigConstants::KEYS[:IS_EACH?]] = true
    config[ConfigConstants::KEYS[:DAY]] = config[ConfigConstants::KEYS[:NTH_DAY]]

    to_specific_date(do_year, config)
  end

  def to_nth_day_in_each_quarter(do_year, config)
    # TODO: Throw config error if invalid
    quarter_months = AppConstants::LISTS[:QUARTER_MONTHS]

    quarter_months.each do |month|
      config[ConfigConstants::KEYS[:MONTH]] = month
      config[ConfigConstants::KEYS[:DAY]] = config[ConfigConstants::KEYS[:NTH_DAY]]
      to_specific_date(do_year, config)
    end
    do_year
  end

  def to_xday_every_n_weeks(do_year, config)
    # TODO: Throw config error if invalid day name
    day_name = config[ConfigConstants::KEYS[:DAY_NAME]]
    n_weeks = config[ConfigConstants::KEYS[:N_WEEKS]]
    new_tag = config[ConfigConstants::KEYS[:TAG]]

    week_number = 1
    last_day_year = nil
    do_year.days.each do |day|
      week_number = 1 if day.year != last_day_year
      if day.name == day_name
        day.tasks.prepend(new_tag) if (week_number % n_weeks).zero?
        week_number += 1
      end
      last_day_year = day.year
    end
    do_year
  end

  def to_easter(do_year, config)
    new_tag = config[ConfigConstants::KEYS[:TAG]]

    days_to_sunday = get_days_to_sunday(do_year.year_number)
    easter_month = get_easter_month(days_to_sunday)
    easter_day = get_easter_day(days_to_sunday, easter_month)

    do_year.days.each do |day|
      day.tasks.prepend(new_tag) if day.month == easter_month && day.month_day == easter_day
    end

    do_year
  end

  def to_good_friday(do_year, config)
    new_tag = config[ConfigConstants::KEYS[:TAG]]

    days_to_sunday = get_days_to_sunday(do_year.year_number)
    easter_month = get_easter_month(days_to_sunday)
    easter_day = get_easter_day(days_to_sunday, easter_month)

    good_friday_month = get_good_friday_month(easter_day, easter_month)
    days_in_good_friday_month = do_year.days_in_months[good_friday_month - 1]
    good_friday_day = get_good_friday_day(days_in_good_friday_month, easter_day)

    do_year.days.each do |day|
      day.tasks.prepend(new_tag) if day.month == good_friday_month && day.month_day == good_friday_day
    end
    do_year
  end

  private

  def get_days_to_sunday(year)
    epact_calc = (24 + 19 * (year % 19)) % 30
    paschal_days = epact_calc - (epact_calc / 28)
    paschal_days - (
      (year + (year / 4) + paschal_days - 13) % 7
    )
  end

  def get_easter_month(days_to_sunday)
    3 + (days_to_sunday + 40) / 44
  end

  def get_easter_day(days_to_sunday, easter_month)
    days_to_sunday + 28 - (
      31 * (easter_month / 4)
    )
  end

  def get_good_friday_month(easter_day, easter_month)
    if easter_day > 2
      easter_month
    else
      easter_month - 1
    end
  end

  def get_good_friday_day(days_in_good_friday_month, easter_day)
    if easter_day == 2
      days_in_good_friday_month
    elsif easter_day == 1
      days_in_good_friday_month - 1
    else
      easter_day - 2
    end
  end
end
