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
      it 'throws an error' do
        expect do
          @config_reader.read_file(TestConstants::CONFIG_FILES[:FAKE_PATH])
        end.to raise_error
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
        expect(first_day[ConfigConstants::KEYS[:METHOD]]).to eql(ConfigConstants::CONFIGURED_TASK_METHODS[:SPECIFIC_DATE])
      end
    end
  end
end
