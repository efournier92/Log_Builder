require_relative '../services/tag_merge_service'

class Day
  attr_accessor :tag_roots, :tag_sources
  attr_reader :year, :month, :month_day, :name
  attr_writer :tasks

  def initialize(name, tasks, year, month, month_day, config_file = nil) # rubocop:disable Metrics/ParameterLists
    @name = name
    @tasks = tasks
    @tag_roots = []
    @tag_sources = {}
    @year = year
    @month = month
    @month_day = month_day
    @config_file = config_file
  end

  def tasks
    @tasks = TagMergeService.render(@tag_roots, @config_file, @tag_sources) if @tasks.nil?

    @tasks
  end
end
