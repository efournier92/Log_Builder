require 'fileutils'

class PrinterService
  DEFAULT_OUTPUT_DIR = './'.freeze

  def initialize(config_file, output_dir = DEFAULT_OUTPUT_DIR)
    @config_file = config_file
    @output_dir = output_dir || DEFAULT_OUTPUT_DIR
  end

  def make_out_dir
    FileUtils.mkdir_p @output_dir
  end

  def print_tasks(out_file, day)
    make_out_dir
    out_file.puts(date_line(day).to_s)
    out_file.puts
    out_file.puts(markdown_block_opener)
    out_file.puts(day.tasks.to_s)
    out_file.puts('```')
    out_file.puts
  end

  def date_line(day)
    "## #{format('%04d', day.year)}-#{format('%02d', day.month)}-#{format('%02d', day.month_day)} | #{day.name}"
  end

  def markdown_block_opener
    "```text\n"
  end

  def markdown_block_closer
    '```'
  end

  def do_block_opener
    "\n### Do\n\n```text\n```\n\n"
  end

  def do_file_name(year, month = nil)
    if !month.nil?
      "#{@output_dir}/DO_#{format('%04d', year)}_#{format('%02d', month)}.md"
    else
      "#{@output_dir}/DO_#{format('%04d', year)}.md"
    end
  end

  def lg_file_name(year)
    "#{@output_dir}/LG_#{format('%04d', year)}.md"
  end

  def print_do_year(do_year)
    make_out_dir
    year = do_year.year_number
    out_file = File.new(do_file_name(year), 'w')
    do_year.days.each do |day|
      print_tasks(out_file, day)
    end
  end

  def print_do_month(do_year, month)
    make_out_dir
    year = do_year.year_number
    out_file = File.new(do_file_name(year, month), 'w')
    do_year.days.each do |day|
      print_tasks(out_file, day) if day.month == month
    end
  end

  def get_template_by_day(day_name)
    reader_service = ConfigReaderService.new(@config_file)
    template_base = reader_service.configured_lg_templates['base']
    day_config = reader_service.configured_lg_templates[day_name.downcase]

    return template_base + day_config unless day_config.nil?

    if Year::WEEKEND_DAY_NAMES.include?(day_name)
      template_base + reader_service.configured_lg_templates['weekend']
    else
      template_base + reader_service.configured_lg_templates['weekday']
    end
  end

  def print_lg(do_year)
    make_out_dir
    year = do_year.year_number
    out_file = File.new(lg_file_name(year), 'w')

    do_year.days.each do |day|
      out_file.puts(date_line(day))
      day_template = get_template_by_day(day.name)
      out_file.puts(day_template)
    end
  end
end
