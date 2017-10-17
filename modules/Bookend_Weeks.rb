module Bookend_Weeks

  def self.shift_do_start(do_year)
    while do_year.weeks.first.days.all? { | day | day.month == 12 }
      do_year.weeks.shift
    end
    do_year
  end

  def self.shift_lg_start(do_year)
    until do_year.weeks.first.days.any? { | day | day.month == 1 }
      first_day = do_year.weeks.first.days.first.month_day
      first_day_month = do_year.weeks.first.days.first.month
      binding.pry
      break if first_day_month == 12 && first_day >= 25
      do_year.weeks.shift 
    end
    do_year.weeks.first.days.shift(5)
    do_year
  end

  def self.shift_do_end(do_year)
    while do_year.weeks.last.days.all? { | day | day.month == 1 }
      do_year.weeks.pop
    end
    do_year
  end

  def self.shift_lg_end(do_year)
    while do_year.weeks.last.days.all? { | day | day.month == 1 }
      do_year.weeks.pop
    end
    do_year.weeks.last.days.pop(2)
    do_year
  end

end

