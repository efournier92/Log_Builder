require_relative './constants/app_constants'
require_relative './modules/log_builder'
require_relative './services/input_validation_service'

if ARGV.first == '--version'
  puts "Log Builder #{AppConstants::VERSION}"
  exit 0
end

arguments = ARGV

config_file = arguments[0]
mode = arguments[1]
year = arguments[2]
month = arguments[3]
output_dir = arguments[4]

config_file = valid_config_file?(config_file) ? config_file : ''
mode = valid_mode?(mode) ? mode : ''
year = valid_year_number?(year) ? year.to_i : nil
month = valid_month?(month, mode) ? sanitize_month(month) : nil
output_dir = valid_output_dir?(output_dir) ? output_dir : nil

builder = LogBuilder.new(config_file, mode, year, month, output_dir)

builder.build_file
