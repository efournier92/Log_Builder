require './src/services/config_reader_service'
require './src/constants/config_constants'
require './test/constants/test_constants'
require 'tmpdir'

describe ConfigReaderService do
  before :each do
    @config_reader = ConfigReaderService.new(TestConstants::CONFIG_FILES[:TEST_PATH])
    @config = @config_reader.read_file(TestConstants::CONFIG_FILES[:TEST_PATH])
  end

  describe '#read_file' do
    context 'given an actual file to read' do
      it 'returns a config based on the file' do
        expect(@config).to be_a(Hash)
      end
    end

    context 'given an nonexistent file to read' do
      it 'raises a FileNotFoundError' do
        expect do
          @config_reader.read_file(TestConstants::CONFIG_FILES[:FAKE_PATH])
        end.to raise_error(
          ConfigReaderService::FileNotFoundError,
          format(ConfigConstants::ERRORS[:FILE_NOT_FOUND], TestConstants::CONFIG_FILES[:FAKE_PATH])
        )
      end
    end

    context 'given an internal node to read' do
      it 'returns a hash' do
        tasks = @config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
        node_name = TestConstants::KEYS[:DIMENSIONAL_2]

        node = tasks[node_name]

        expect(node).to be_an_instance_of(Hash)
      end
    end

    context 'given a leaf node to read' do
      it 'returns an array' do
        tasks = @config[ConfigConstants::KEYS[:TASK_TEMPLATES]]
        node_name = TestConstants::KEYS[:DIMENSIONAL_1]

        node = tasks[node_name]

        expect(node).to be_an_instance_of(Array)
      end
    end
  end

  describe '#get_configured_tasks' do
    context 'given a valid config' do
      it 'returns a hash with configured tasks' do
        tags = @config_reader.configured_tasks
        first_day = tags[TestConstants::HOLIDAYS[:FIRST_DAY]]

        expect(tags).to be_an_instance_of(Hash)
        expect(first_day[ConfigConstants::KEYS[:TEMPLATE]]).to eql(ConfigConstants::TEMPLATE_TYPES[:HOLIDAY])
        expect(first_day[ConfigConstants::KEYS[:METHOD]]).to eql(
          ConfigConstants::BIRTH_YEAR_METHODS[:SPECIFIC_DATE]
        )
      end
    end
  end

  describe '#configured_template_by_name' do
    context 'given a known template name' do
      it 'returns the template hash' do
        template = @config_reader.configured_template_by_name(ConfigConstants::TEMPLATE_TYPES[:HOLIDAY])

        expect(template).to be_an_instance_of(Hash)
        expect(template.keys).to include(ConfigConstants::TEMPLATE_TYPES[:HOLIDAY])
      end
    end

    context 'given an unknown template name' do
      it 'returns nil' do
        expect(@config_reader.configured_template_by_name('Nonexistent')).to be_nil
      end
    end
  end

  describe '#configured_lg_templates' do
    context 'given a valid config' do
      it 'returns the lg templates hash' do
        lg_templates = @config_reader.configured_lg_templates

        expect(lg_templates).to be_an_instance_of(Hash)
        expect(lg_templates.keys).to include(ConfigConstants::KEYS[:LG_TEMPLATE_BASE])
      end
    end
  end

  describe '#tag_order' do
    context 'given a config that defines tag_order_config' do
      it 'returns the configured list' do
        reader = ConfigReaderService.new(TestConstants::CONFIG_FILES[:ORDER_PATH])

        expect(reader.tag_order).to eq(%w[Holiday Birthday Career ~~OTHER~~ Body])
      end
    end

    context 'given a non-list value' do
      it 'returns it unchanged for later validation' do
        allow(YAML).to receive(:load_file).and_return(ConfigConstants::KEYS[:TAG_ORDER] => false)
        reader = ConfigReaderService.new(TestConstants::CONFIG_FILES[:TEST_PATH])

        expect(reader.tag_order).to be(false)
      end
    end

    context 'given a config that does not define tag_order_config' do
      it 'returns an empty array' do
        expect(@config_reader.tag_order).to eq([])
      end

      it 'returns an empty array for the blank config' do
        reader = ConfigReaderService.new(TestConstants::CONFIG_FILES[:BLANK_PATH])

        expect(reader.tag_order).to eq([])
      end
    end
  end

  describe 'reading a blank config' do
    before :each do
      @blank_reader = ConfigReaderService.new(TestConstants::CONFIG_FILES[:BLANK_PATH])
    end

    context 'given a config that lacks the lg template keys' do
      it 'returns the task templates without raising and nil lg templates' do
        expect { @blank_reader.configured_task_templates }.not_to raise_error
        expect(@blank_reader.configured_task_templates).to be_a(Hash)
        expect(@blank_reader.configured_lg_templates).to be_nil
      end

      it 'returns the configured task template by name' do
        expect(@blank_reader.configured_template_by_name(ConfigConstants::TEMPLATE_TYPES[:HOLIDAY])).to be_a(Hash)
      end
    end

    context 'given a config that lacks the tasks key' do
      it 'returns an empty hash of configured tasks' do
        expect(@blank_reader.configured_tasks).to eq({})
      end
    end
  end

  describe '.validate!' do
    def in_tmp_config(contents)
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'config.yml')
        File.write(path, contents)
        yield path
      end
    end

    def validation_problem(contents, validation_mode: 'DO')
      in_tmp_config(contents) do |path|
        ConfigReaderService.validate!(path, mode: validation_mode)
        nil
      rescue ConfigReaderService::InvalidConfigError => e
        e.message
      end
    end

    context 'given valid fixture configs' do
      it 'returns a Hash and raises nothing' do
        expect(ConfigReaderService.validate!(TestConstants::CONFIG_FILES[:TEST_PATH], mode: 'DO')).to be_a(Hash)
        expect(ConfigReaderService.validate!(TestConstants::CONFIG_FILES[:ORDER_PATH], mode: 'DO')).to be_a(Hash)
      end
    end

    context 'given a YAML syntax error' do
      it 'reports a syntax error rather than a backtrace' do
        expect(validation_problem("tasks_config:\n  Bad: [unclosed\n")).to match(/YAML syntax error/)
      end
    end

    context 'given a duplicate key' do
      it 'reports the duplicate key and its section' do
        contents = <<~YAML
          tasks_config:
            A:
              method: to_each_day
              template: T
          tasks_config:
            B:
              method: to_each_day
              template: T
        YAML

        expect(validation_problem(contents)).to include("duplicate key 'tasks_config' in top level")
      end
    end

    context 'given an unknown method' do
      it 'reports the unknown method' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_nope
              template: T
        YAML

        expect(validation_problem(contents)).to include("unknown method 'to_nope'")
      end
    end

    context 'given a method missing a required key' do
      it 'reports the missing key' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_xday_every_n_weeks
              day_name: Monday
              template: T
        YAML

        expect(validation_problem(contents)).to include("missing required key 'n_weeks' for to_xday_every_n_weeks")
      end
    end

    context 'given a conditional key' do
      it 'accepts to_specific_date with is_each and no month' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_specific_date
              is_each: true
              day: 1
              template: T
        YAML

        in_tmp_config(contents) { |path| expect(ConfigReaderService.validate!(path, mode: 'DO')).to be_a(Hash) }
      end

      it 'reports the missing month without is_each' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_specific_date
              day: 1
              template: T
        YAML

        expect(validation_problem(contents)).to include("missing required key 'month' for to_specific_date")
      end
    end

    context 'given a forbidden key' do
      it 'reports the key as not allowed' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_each_day
              day_name: Monday
              template: T
        YAML

        expect(validation_problem(contents)).to include("key 'day_name' is not allowed for to_each_day")
      end
    end

    context 'given wrong value types and ranges' do
      it 'reports a quoted month as a type error' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_specific_date
              month: "1"
              day: 1
              template: T
        YAML

        expect(validation_problem(contents)).to include("'month' must be an Integer")
      end

      it 'reports n_weeks below one as a range error' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_xday_every_n_weeks
              day_name: Monday
              n_weeks: 0
              template: T
        YAML

        expect(validation_problem(contents)).to include("'n_weeks' must be at least 1")
      end

      it 'reports an invalid lowercase day name' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_each_xday
              day_name: monday
              template: T
        YAML

        expect(validation_problem(contents)).to include("invalid day name 'monday'")
      end
    end

    context 'given an unknown top-level key' do
      it 'reports the unknown key' do
        contents = <<~YAML
          templates_config:
            T:
              - X
        YAML

        expect(validation_problem(contents)).to include("unknown top-level key 'templates_config'")
      end
    end

    context 'given missing sections' do
      it 'requires task_templates_config when tasks are present' do
        contents = <<~YAML
          tasks_config:
            Bad:
              method: to_each_day
              template: T
        YAML

        expect(validation_problem(contents))
          .to include('task_templates_config is required when tasks_config is present')
      end

      it 'accepts a config with no tasks' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
        YAML

        in_tmp_config(contents) { |path| expect(ConfigReaderService.validate!(path, mode: 'DO')).to be_a(Hash) }
      end

      it 'requires lg_templates_config for mode LG' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
        YAML

        expect(validation_problem(contents, validation_mode: 'LG'))
          .to include('lg_templates_config is required when mode is LG')
      end

      it 'does not require lg_templates_config for mode DO' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
        YAML

        in_tmp_config(contents) { |path| expect(ConfigReaderService.validate!(path, mode: 'DO')).to be_a(Hash) }
      end
    end

    context 'given template resolution' do
      it 'reports a String name that does not resolve' do
        contents = <<~YAML
          task_templates_config:
            T:
              - X
          tasks_config:
            Bad:
              method: to_each_day
              template: Missing
        YAML

        expect(validation_problem(contents)).to include("no template named 'Missing'")
      end

      it 'accepts an inline Hash template' do
        contents = <<~YAML
          task_templates_config:
            Unused:
              - X
          tasks_config:
            Bad:
              method: to_each_day
              template:
                T:
                  - X
        YAML

        in_tmp_config(contents) { |path| expect(ConfigReaderService.validate!(path, mode: 'DO')).to be_a(Hash) }
      end
    end

    context 'given multiple problems' do
      it 'reports them all in one message' do
        contents = <<~YAML
          tasks_config:
            Bad:
              method: to_nope
              template: T
        YAML

        problem = validation_problem(contents)

        expect(problem).to include('task_templates_config is required when tasks_config is present')
        expect(problem).to include("unknown method 'to_nope'")
      end
    end
  end
end
