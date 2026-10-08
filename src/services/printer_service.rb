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
    atomic_write(do_file_name(year)) do |out_file|
      do_year.days.each do |day|
        print_tasks(out_file, day)
      end
    end
  end

  def print_do_month(do_year, month)
    make_out_dir
    year = do_year.year_number
    atomic_write(do_file_name(year, month)) do |out_file|
      do_year.days.each do |day|
        print_tasks(out_file, day) if day.year == year && day.month == month
      end
    end
  end

  def get_template_by_day(day_name)
    @reader ||= ConfigReaderService.new(@config_file)
    template_base = @reader.configured_lg_templates[ConfigConstants::KEYS[:LG_TEMPLATE_BASE]]
    day_config = @reader.configured_lg_templates[day_name.downcase]

    return template_base + day_config unless day_config.nil?

    if Year::WEEKEND_DAY_NAMES.include?(day_name)
      template_base + @reader.configured_lg_templates[ConfigConstants::KEYS[:LG_TEMPLATE_WEEKEND]]
    else
      template_base + @reader.configured_lg_templates[ConfigConstants::KEYS[:LG_TEMPLATE_WEEKDAY]]
    end
  end

  def print_lg(do_year)
    make_out_dir
    year = do_year.year_number
    atomic_write(lg_file_name(year)) do |out_file|
      do_year.days.each do |day|
        out_file.puts(date_line(day))
        day_template = get_template_by_day(day.name)
        out_file.puts(day_template)
      end
    end
  end

  # Write via a sibling temp file so a render failure never truncates the existing target.
  def atomic_write(path)
    temp_path = "#{path}.tmp.#{Process.pid}"
    result = nil
    File.open(temp_path, 'w') { |out_file| result = yield out_file }
    File.rename(temp_path, path)
    puts "Wrote #{path}"
    result
  ensure
    File.delete(temp_path) if File.exist?(temp_path)
  end
end
