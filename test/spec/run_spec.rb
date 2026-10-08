require 'open3'
require 'tmpdir'
require './src/constants/app_constants'
require './test/constants/test_constants'

def run_cli(*args)
  Open3.capture3('ruby', './src/run.rb', *args)
end

describe 'run.rb' do
  context 'given a valid DO argument with a month' do
    it 'writes DO_<year>_<month>.md with the expected date line' do
      Dir.mktmpdir do |dir|
        stdout, _stderr, status = run_cli(TestConstants::CONFIG_FILES[:TEST_PATH], 'DO', '2020', '1', dir)
        file = File.join(dir, 'DO_2020_01.md')

        expect(status.exitstatus).to eq(0)
        expect(File.exist?(file)).to be true
        expect(File.read(file)).to include('## 2020-01-01 | Wednesday')
        expect(stdout).to include('Wrote ')
      end
    end
  end

  context 'given a valid DO argument with ALL' do
    it 'writes DO_<year>.md with the expected date line' do
      Dir.mktmpdir do |dir|
        _stdout, _stderr, status = run_cli(TestConstants::CONFIG_FILES[:TEST_PATH], 'DO', '2020', 'ALL', dir)
        file = File.join(dir, 'DO_2020.md')

        expect(status.exitstatus).to eq(0)
        expect(File.exist?(file)).to be true
        expect(File.read(file)).to include('## 2020-01-01 | Wednesday')
      end
    end
  end

  context 'given a valid LG argument' do
    it 'writes LG_<year>.md with the expected date line' do
      Dir.mktmpdir do |dir|
        _stdout, _stderr, status = run_cli(TestConstants::CONFIG_FILES[:TEST_PATH], 'LG', '2020', 'ALL', dir)
        file = File.join(dir, 'LG_2020.md')

        expect(status.exitstatus).to eq(0)
        expect(File.exist?(file)).to be true
        expect(File.read(file)).to include('## 2020-01-01 | Wednesday')
      end
    end
  end

  context 'given a missing config path' do
    it 'prints the invalid config message' do
      Dir.mktmpdir do |dir|
        stdout, _stderr, _status = run_cli(TestConstants::CONFIG_FILES[:FAKE_PATH], 'DO', '2020', '1', dir)

        expect(stdout).to include(AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_FILE])
      end
    end

    it 'exits non-zero' do
      Dir.mktmpdir do |dir|
        _stdout, _stderr, status = run_cli(TestConstants::CONFIG_FILES[:FAKE_PATH], 'DO', '2020', '1', dir)

        expect(status.exitstatus).to_not eq(0)
      end
    end
  end

  context 'given a malformed config' do
    it 'exits non-zero, reports to STDERR, and writes no output file' do
      Dir.mktmpdir do |dir|
        config = File.join(dir, 'bad_config.yml')
        File.write(config, "tasks_config:\n  Bad:\n    method: to_nope\n    template: T\n")

        _stdout, stderr, status = run_cli(config, 'DO', '2020', 'ALL', dir)

        expect(status.exitstatus).to_not eq(0)
        expect(stderr).to include("unknown method 'to_nope'")
        expect(Dir.children(dir)).to eq([File.basename(config)])
      end
    end
  end

  context 'given an LG config with mixed template types and a pre-existing output file' do
    it 'rejects the config at load, reports to STDERR, and leaves the existing file untouched' do
      Dir.mktmpdir do |dir|
        config = File.join(dir, 'lg_config.yml')
        File.write(config, <<~YAML)
          lg_templates_config:
            base:
              - ""
            weekday:
              - ""
            weekend:
              - ""
            monday: not_a_list
        YAML
        target = File.join(dir, 'LG_2020.md')
        File.write(target, "pre-existing\n")

        _stdout, stderr, status = run_cli(config, 'LG', '2020', 'ALL', dir)

        expect(status.exitstatus).to_not eq(0)
        expect(stderr).to include('lg_templates_config')
        expect(File.read(target)).to eq("pre-existing\n")
        expect(Dir.children(dir).sort).to eq(%w[LG_2020.md lg_config.yml])
      end
    end
  end
end
