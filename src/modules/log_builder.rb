require_relative '../models/year'
require_relative '../constants/app_constants'
require_relative '../services/printer_service'
require_relative '../services/add_task_service'
require_relative '../services/input_validation_service'

# Main class to kickstart the file-printing process according to initialized values
class LogBuilder
  attr_reader :mode, :year_number, :month

  def initialize(config_file, mode, year_number, month, output_directory = nil)
    @config_file = config_file
    @mode = mode
    @year_number = year_number
    @month = month
    @output_directory = output_directory

    unless valid_config_file?(@config_file)
      puts AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_FILE]
      raise SystemExit
    end
  end

  def build_file
    collect_user_input
    build_by_mode
  end

  def collect_user_input
    prompt_for_mode_input until valid_mode?(@mode)

    prompt_for_year_input until valid_year_number?(@year_number)

    prompt_for_month_input until valid_month?(@month, @mode)
  end

  def build_by_mode
    printer_service = PrinterService.new(@config_file, @output_directory)
    do_year = Year.new(@year_number, @config_file)

    if @mode == AppConstants::MODES[:DO]
      build_do(do_year, printer_service)
    elsif @mode == AppConstants::MODES[:LG]
      build_lg(do_year, printer_service)
    end
  end

  def build_do(do_year, printer_service)
    if print_month?(month)
      printer_service.print_do_month(do_year, @month)
    else
      printer_service.print_do_year(do_year)
    end
  end

  def build_lg(do_year, printer_service)
    printer_service.print_lg(do_year)
  end

  def prompt_for_mode_input
    print AppConstants::INPUT_PROMPTS[:MODE]
    @mode = $stdin&.gets&.chomp&.upcase
  end

  def prompt_for_year_input
    print AppConstants::INPUT_PROMPTS[:YEAR]
    @year_number = $stdin&.gets&.chomp.to_i
  end

  def prompt_for_month_input
    print AppConstants::INPUT_PROMPTS[:MONTH]
    @month = $stdin&.gets&.chomp&.upcase
    @month = @month.to_i if valid_month_pattern?(@month)
  end
end
