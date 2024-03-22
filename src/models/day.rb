class Day
  attr_accessor :tasks
  attr_reader :year, :month, :month_day, :name

  def initialize(name, tasks, year, month, month_day)
    @name = name
    @tasks = tasks
    @year = year
    @month = month
    @month_day = month_day
  end
end
