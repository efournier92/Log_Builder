require_relative './config_reader_service'
require_relative '../constants/config_constants'

class TaskPrinterService
  attr_reader :output

  def initialize(config_file)
    @config_file = config_file
    @output = ''
    @current_depth = 0
    @current_node = 0
  end

  def print(task)
    print_node(task)
    "#{@output}\n"
  end

  def append_output(text)
    @output << text
  end

  def print_node(node)
    if leaf?(node)
      print_leaf(node)
    else
      print_internal(node)
    end
  end

  def print_leaf(node)
    return if node.nil?

    node.each do |text|
      append_leaf(text)
      @current_node += 1
    end
  end

  def print_internal(node)
    return if node.nil?

    node.each do |text, task|
      if template_string?(text)
        @reader ||= ConfigReaderService.new(@config_file)
        name = get_name_from_placeholder(text)
        configured_template = @reader.configured_template_by_name(name)
        # TODO: Inform user if configured_template.nil?
        begin
          text = configured_template.keys[0]
          task = configured_template.values[0]
        rescue StandardError
          # TODO: Implement error-handling service
          puts "TEXT: #{text}"
          puts "TASK: #{task}"
        end
      end
      if task.nil?
        append_leaf(text)
      else
        append_internal(text)
        @current_node += 1
        increment_depth
        print_node(task)
        decrement_depth
        print_closer
      end
    end
  end

  def append_internal(text)
    append_output("\n") if @current_depth.zero? && @current_node.positive?
    append_spacing
    append_output(text)
    append_output('(')
  end

  def append_leaf(text)
    append_output("\n") if @current_depth.zero? && @current_node.positive?
    append_spacing
    append_output(text)
    append_output(',')
  end

  def print_closer
    append_output("\n")
    append_indents(@current_depth)
    append_output('),')
  end

  def append_spacing
    append_output("\n") if @current_depth.positive?
    append_indents(@current_depth)
  end

  def append_indents(depth)
    append_output(' ' * depth * 2)
  end

  def leaf?(node)
    node.is_a?(Array)
  end

  def increment_depth
    @current_depth += 1
  end

  def decrement_depth
    @current_depth -= 1
  end

  def update_content_array(template_placeholders, template_variables)
    template_placeholders.each do |template_string|
      template_placeholder = get_placeholder(template_string)

      mapping = template_variables.detect { |m| m.keys[0] == template_placeholder }

      next if mapping.nil?

      replace_template_content(template_string, template_placeholder, mapping.values[0])
    end
  end

  def update_content_hash(template_to_update, template_variables)
    template_to_update.each_value do |template_placeholders|
      if template_placeholders.is_a?(Array)
        update_content_array(template_placeholders, template_variables)
      else
        update_content_hash(template_placeholders, template_variables)
      end
    end
  end

  def print_from_template(template, template_variables)
    print(resolve_template(template, template_variables))
  end

  def resolve_template(template, template_variables)
    return template if template_variables.nil?

    # Clone to avoid mutating the original template
    template_to_update = Marshal.load(Marshal.dump(template))

    update_content_hash(template_to_update, template_variables)

    template_to_update
  end

  def get_name_from_placeholder(input)
    start_marker = ConfigConstants::PLACEHOLDERS[:TEMPLATE_START]
    end_marker = ConfigConstants::PLACEHOLDERS[:TEMPLATE_END]
    content_between_markers = input[/#{Regexp.escape(start_marker)}(.*?)#{Regexp.escape(end_marker)}/m, 1]

    return input if content_between_markers.nil?

    content_between_markers
  end

  def get_placeholder(input)
    start_marker = ConfigConstants::PLACEHOLDERS[:TEMPLATE_START]
    end_marker = ConfigConstants::PLACEHOLDERS[:TEMPLATE_END]
    content_between_markers = input[/#{Regexp.escape(start_marker)}(.*?)#{Regexp.escape(end_marker)}/m, 1]

    return input if content_between_markers.nil?

    start_marker + content_between_markers + end_marker
  end

  def template_string?(string)
    string.include?(ConfigConstants::PLACEHOLDERS[:TEMPLATE_START]) &&
      string.include?(ConfigConstants::PLACEHOLDERS[:TEMPLATE_END])
  end

  def replace_template_content(string_with_placeholder, placeholder, content)
    string_with_placeholder.gsub!(placeholder, content)
  end
end
