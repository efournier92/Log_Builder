require './src/services/config_reader_service'
require './src/constants/config_constants'
require './test/constants/test_constants'

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
          ConfigConstants::CONFIGURED_TASK_METHODS[:SPECIFIC_DATE]
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

        expect(reader.tag_order).to eq(%w[Holiday Birthday Career ~OTHER~ Body])
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

    context 'given a config that lacks the template keys' do
      it 'returns nil task and lg template sections without raising' do
        expect { @blank_reader.configured_task_templates }.not_to raise_error
        expect(@blank_reader.configured_task_templates).to be_nil
        expect(@blank_reader.configured_lg_templates).to be_nil
      end

      it 'returns nil for a template lookup by name' do
        expect(@blank_reader.configured_template_by_name(ConfigConstants::TEMPLATE_TYPES[:HOLIDAY])).to be_nil
      end
    end

    context 'given a config that lacks the tasks key' do
      it 'returns an empty hash of configured tasks' do
        expect(@blank_reader.configured_tasks).to eq({})
      end
    end
  end
end
