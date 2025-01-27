require './src/services/config_reader_service'
require './src/services/task_printer_service'
require './test/constants/test_constants'
require './src/constants/config_constants'

describe TaskPrinterService do
  before :each do
    config_file = TestConstants::CONFIG_FILES[:TEST_PATH]
    @config_reader = ConfigReaderService.new(config_file)
    @config = @config_reader.read_file(config_file)
    @config_templates = @config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
    @printer = TaskPrinterService.new(TestConstants::CONFIG_FILES[:TEST_PATH])
  end

  context 'given a single 1-dimentional task to print' do
    it 'formats the task appropriately' do
      task_name = TestConstants::KEYS[:DIMENSIONAL_1]
      task = @config_templates[task_name]

      task_printed = @printer.print(task)

      expected_output = "Level_1,\n"
      expect(task_printed).to eq(expected_output)
    end
  end

  context 'given multiple 1-dimentional tasks to print' do
    it 'formats the task appropriately' do
      task_name = TestConstants::KEYS[:DIMENSIONAL_1_DOUBLE]
      task = @config_templates[task_name]

      task_printed = @printer.print(task)

      expected_output = "Level_1a,\nLevel_1b,\n"
      expect(task_printed).to eq(expected_output)
    end
  end

  context 'given a 2-dimentional task to print' do
    it 'formats the task appropriately' do
      task_name = TestConstants::KEYS[:DIMENSIONAL_2]
      task = @config_templates[task_name]

      task_printed = @printer.print(task)

      expected_output = "Level_1(\n  Level_2,\n),\n"
      expect(task_printed).to eq(expected_output)
    end
  end

  context 'given a 3-dimentional task to print' do
    it 'formats the task appropriately' do
      task_name = TestConstants::KEYS[:DIMENSIONAL_3]
      task = @config_templates[task_name]

      task_printed = @printer.print(task)

      expected_output = "Level_1(\n  Level_2(\n    Level_3,\n  ),\n),\n"
      expect(task_printed).to eq(expected_output)
    end
  end

  context 'given a 3-dimentional task to print with leaf siblings on the bottom level' do
    it 'formats the task appropriately' do
      task_name = TestConstants::KEYS[:DIMENSIONAL_3_SIBLINGS_LEAF]
      task = @config_templates[task_name]

      task_printed = @printer.print(task)

      expected_output = "Level_1(\n  Level_2(\n    Level_3,\n    Level_3,\n  ),\n),\n"
      expect(task_printed).to eq(expected_output)
    end
  end

  context 'given a 3-dimentional task to print with internal siblings on the middle level' do
    it 'formats the task appropriately' do
      task_name = TestConstants::KEYS[:DIMENSIONAL_3_SIBLINGS_INTERNAL]
      task = @config_templates[task_name]

      task_printed = @printer.print(task)

      expected_output = "Level_1(\n  Level_2a(\n    Level_3,\n  ),\n  Level_2b(\n    Level_3,\n  ),\n),\n"
      expect(task_printed).to eq(expected_output)
    end
  end

  context 'given a 2-dimentional task to print with mixed leaf and internal siblings' do
    it 'formats the task appropriately' do
      task_name = TestConstants::KEYS[:DIMENSIONAL_2_MIXED]
      task = @config_templates[task_name]

      task_printed = @printer.print(task)

      expected_output = "Level_1a(\n  Level_2a(\n    Level_3a,\n  ),\n  Level_2b,\n),\n"
      expect(task_printed).to eq(expected_output)
    end
  end

  describe '#append_output' do
    context 'given text to append with no existing output' do
      before :each do
        text = 'TextToAppend'

        @output = @printer.append_output(text)

        @expected_output = text
      end

      it 'returns the appended text' do
        expect(@output).to eql(@expected_output)
      end

      it 'appends the text to output attribute' do
        expect(@printer.output).to eql(@expected_output)
      end
    end

    context 'given text to append with existing output' do
      before :each do
        initial_text = 'InitialToAppend'
        appended_text = 'AppendedText'

        @printer.append_output(initial_text)
        @output = @printer.append_output(appended_text)

        @expected_output = initial_text + appended_text
      end

      it 'returns an string with text appended to the existing output' do
        expect(@output).to eql(@expected_output)
      end

      it 'appends the string he output attribute' do
        expect(@printer.output).to eql(@expected_output)
      end
    end

    context 'given an empty string to append' do
      before :each do
        text = ''

        @output = @printer.append_output(text)

        @expected_output = ''
      end

      it 'returns an empty string' do
        expect(@output).to eql(@expected_output)
      end

      it 'appends nothing to the output attribute' do
        expect(@printer.output).to eql(@expected_output)
      end
    end
  end

  describe '#append_indents' do
    context 'given the supplied depth is 0' do
      it 'does not append any indent to the output attribute' do
        initial_text = 'InitialText'
        final_text = 'FinalText'
        depth = 0

        @printer.append_output(initial_text)
        @printer.append_indents(depth)
        @printer.append_output(final_text)

        expected_output = initial_text + final_text

        expect(@printer.output).to eql(expected_output)
      end
    end
  end

  context 'given the supplied depth is 1' do
    it 'appends an indent of 2 spaces to the output attribute' do
      initial_text = 'InitialText'
      final_text = 'FinalText'
      expected_indent = '  '
      depth = 1

      @printer.append_output(initial_text)
      @printer.append_indents(depth)
      @printer.append_output(final_text)

      expected_output = initial_text + expected_indent + final_text

      expect(@printer.output).to eql(expected_output)
    end
  end

  describe '#leaf' do
    context 'given a leaf node' do
      it 'returns true' do
        node_name = TestConstants::KEYS[:DIMENSIONAL_1]
        node = @config_templates[node_name]

        output = @printer.leaf?(node)

        expect(output).to be true
      end
    end

    context 'given an internal node' do
      it 'returns false' do
        node_name = TestConstants::KEYS[:DIMENSIONAL_3]
        node = @config_templates[node_name]

        output = @printer.leaf?(node)

        expect(output).to be false
      end
    end

    context 'given nil' do
      it 'returns false' do
        node = nil

        output = @printer.leaf?(node)

        expect(output).to be false
      end
    end

    context 'given a string' do
      it 'returns false' do
        node = 'BadInput'

        output = @printer.leaf?(node)

        expect(output).to be false
      end
    end
  end

  describe '#increment_depth' do
    context 'given a call to #increment_depth' do
      it 'increments currentDepth by 1 on each call' do
        output = @printer.increment_depth

        expect(output).to eql(1)

        output = @printer.increment_depth

        expect(output).to eql(2)
      end
    end
  end

  describe '#decrement_depth' do
    context 'given a call to #decrement_depth' do
      it 'decrements currentDepth by 1 on each call' do
        @printer.increment_depth
        output = @printer.increment_depth
        expect(output).to eql(2)

        output = @printer.decrement_depth
        expect(output).to eql(1)

        output = @printer.decrement_depth
        expect(output).to eql(0)
      end
    end
  end

  describe '#print_from_template' do
    context 'given a configured task with a configured template' do
      it 'inserts the configured task content inside the template' do
        task = @config[ConfigConstants::KEYS[:TASKS]][TestConstants::HOLIDAYS[:FIRST_DAY]]
        content = task[ConfigConstants::KEYS[:TEMPLATE_VARIABLES]]
        template_name = task[ConfigConstants::KEYS[:TEMPLATE]]
        template = @config[ConfigConstants::KEYS[:TASK_TEMPLATES]][template_name]

        output = @printer.print_from_template(template, content)

        expect(output).to eql("Holiday(\n  #{TestConstants::HOLIDAYS[:FIRST_DAY]},\n),\n")
      end
    end

    context 'given a configured task with a configured template with multiple placeholders' do
      it 'inserts the replaces each placeholder appropriately' do
        task = @config[ConfigConstants::KEYS[:TASKS]][TestConstants::KEYS[:BIRTHDAY_PERSON]]
        content = task[ConfigConstants::KEYS[:TEMPLATE_VARIABLES]]
        template_name = task[ConfigConstants::KEYS[:TEMPLATE]]
        template = @config[ConfigConstants::KEYS[:TASK_TEMPLATES]][template_name]

        output = @printer.print_from_template(template, content)

        content_name = 'Name(PersonsName,)'
        content_contact = 'Contact(000-000-0000,)'

        expected_output = "Birthday(\n  #{content_name},\n  #{content_contact},\n),\n"
        expect(output).to eql(expected_output)
      end
    end
  end

  describe '#template_string' do
    context 'given a template node' do
      it 'returns true' do
        input = '{{CONTENT}}'

        output = @printer.template_string?(input)

        expect(output).to eql(true)
      end
    end

    context 'given random template content' do
      it 'returns true' do
        input = '{{FXJWISJFWE}}'

        output = @printer.template_string?(input)

        expect(output).to eql(true)
      end
    end

    context 'given a non-template node' do
      it 'returns false' do
        input = 'some string'

        output = @printer.template_string?(input)

        expect(output).to eql(false)
      end
    end
  end

  describe '#replace_template_content' do
    context 'given a template for content replacement' do
      it 'replaces the placeholder with content' do
        template = 'This_{{CONTENT}}_Tag'
        placeholder = '{{CONTENT}}'
        content = 'Example'
        output = @printer.replace_template_content(template, placeholder, content)

        expected_output = 'This_Example_Tag'
        expect(output).to eql(expected_output)
      end
    end
  end

  describe '#get_placeholder' do
    context 'given a string containing placeholder content' do
      it 'returns the placeholder content along' do
        input = 'This_{{CONTENT}}_Tag'

        output = @printer.get_placeholder(input)

        expected_output = '{{CONTENT}}'
        expect(output).to eql(expected_output)
      end
    end
  end
end
