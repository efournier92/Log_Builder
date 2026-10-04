def valid_config_file?(config_file)
  config_file.is_a?(String) && File.exist?(config_file)
end

def valid_mode?(mode)
  mode == AppConstants::MODES[:DO] || mode == AppConstants::MODES[:LG]
end

def valid_year_number?(year_number)
  year_number.to_i.positive?
end

def valid_month?(month, mode)
  lg_mode?(mode) || all_mode?(month) || valid_month_number?(month)
end

def valid_output_dir?(output_dir)
  output_dir.is_a?(String)
end

def lg_mode?(mode)
  mode == AppConstants::MODES[:LG]
end

def all_mode?(month)
  month == AppConstants::MODES[:ALL]
end

def valid_month_number?(month)
  !month.nil? && month.to_i.positive? && month.to_i <= 12
end

def valid_month_pattern?(month)
  !month.nil? && month.is_a?(String) && month.match?(AppConstants::REGEX[:VALID_MONTH])
end

def all_month?(month)
  month == AppConstants::MODES[:ALL]
end

def print_month?(month)
  month.is_a?(Integer) && month.positive?
end

def sanitize_month(month)
  if all_mode?(month)
    month
  else
    month.to_i
  end
end
