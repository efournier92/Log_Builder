require './src/modules/log_builder'
require './src/services/input_validation_service'
require './src/constants/app_constants'
require './test/constants/test_constants'

describe LogBuilder do
  describe '#prompt_for_mode_input' do
    context 'given the user supplies a valid mode' do
      let(:input) { StringIO.new(AppConstants::MODES[:DO]) }

      it 'prompts for mode input' do
        builder = LogBuilder.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil)

        expect(valid_mode?(builder.mode)).to be false

        $stdin = input
        expect { builder.prompt_for_mode_input }.to output(
          AppConstants::INPUT_PROMPTS[:MODE]
        ).to_stdout.and change { builder.mode }.to(AppConstants::MODES[:DO])

        $stdin = STDIN

        expect(valid_mode?(builder.mode)).to be true
      end
    end

    context 'given the user supplies an invalid config file' do
      let(:invalid_config_file) { StringIO.new('fake_directory/fake_file.md') }
      let(:builder) { LogBuilder.new(invalid_config_file, '', '', '', '') }

      it 'informs the user and terminates execution' do
        $stdin = invalid_config_file

        expect { builder.prompt_for_mode_input }.to output(
          "#{AppConstants::ERROR_MESSAGES[:INVALID_CONFIG_FILE]}\n"
        ).to_stdout.and raise_error(SystemExit)
      end
    end

    context 'given the user supplies an invalid mode' do
      let(:invalid_input) { StringIO.new('DUN') }
      let(:valid_input) { StringIO.new(AppConstants::MODES[:DO]) }
      let(:builder) { LogBuilder.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil) }

      it 'prompts for mode input again after invalid input' do
        $stdin = invalid_input

        expect(valid_mode?(builder.mode)).to be false

        expect { builder.prompt_for_mode_input }.to output(
          AppConstants::INPUT_PROMPTS[:MODE]
        ).to_stdout.and change { builder.mode }.to('DUN')

        expect(valid_mode?(builder.mode)).to be false
      end

      it 'accepts valid input' do
        $stdin = valid_input

        expect { builder.prompt_for_mode_input }.to output(
          AppConstants::INPUT_PROMPTS[:MODE]
        ).to_stdout.and change { builder.mode }.to(AppConstants::MODES[:DO])

        expect(valid_mode?(builder.mode)).to be true
      end
    end
  end

  describe '#prompt_for_year_input' do
    context 'given the user supplies an invalid year, then a valid one' do
      let(:builder) { LogBuilder.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil) }
      let(:invalid_input_zero) { StringIO.new('0') }
      let(:invalid_input_negative) { StringIO.new('-1') }
      let(:invalid_input_letter) { StringIO.new('a') }
      let(:valid_input) { StringIO.new('2024') }

      it 'prompts for year input again after zero input' do
        $stdin = invalid_input_zero

        expect(valid_year_number?(builder.year_number)).to be false

        expect { builder.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { builder.year_number }.to(0)

        expect(valid_year_number?(builder.year_number)).to be false
      end

      it 'prompts for year input again after negative input' do
        $stdin = invalid_input_negative

        expect(valid_year_number?(builder.year_number)).to be false

        expect { builder.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { builder.year_number }.to(-1)

        expect(valid_year_number?(builder.year_number)).to be false

        $stdin = STDIN
      end

      it 'prompts for year input again after letter input' do
        $stdin = invalid_input_letter

        expect(valid_year_number?(builder.year_number)).to be false

        expect { builder.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { builder.year_number }.to('a'.to_i)

        expect(valid_year_number?(builder.year_number)).to be false

        $stdin = STDIN
      end

      it 'accepts valid input' do
        $stdin = valid_input

        expect(valid_year_number?(builder.year_number)).to be false

        expect { builder.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { builder.year_number }.to(2024)

        expect(valid_year_number?(builder.year_number)).to be true

        $stdin = STDIN
      end
    end
  end

  describe '#prompt_for_month_input' do
    let(:builder) { LogBuilder.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil) }
    let(:invalid_input_empty) { StringIO.new('') }
    let(:invalid_input_zero) { StringIO.new('0') }
    let(:invalid_input_negative) { StringIO.new('-1') }
    let(:invalid_input_letter) { StringIO.new('a') }
    let(:invalid_input_high_number) { StringIO.new('13') }
    let(:valid_input) { StringIO.new('1') }
    let(:valid_input_all_mode) { StringIO.new(AppConstants::MODES[:ALL]) }

    context 'given the user supplies an empty month' do
      it 'prompts for input again' do
        $stdin = invalid_input_empty

        expect(valid_month?(builder.month, builder.mode)).to be false

        expect { builder.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout

        expect(valid_month?(builder.month, builder.mode)).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies a negative month' do
      it 'prompts for input again' do
        $stdin = invalid_input_negative

        expect(valid_month?(builder.month, builder.mode)).to be false

        expect { builder.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { builder.month }.to('-1')

        expect(valid_month?(builder.month, builder.mode)).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies a letter month' do
      it 'prompts for input again' do
        $stdin = invalid_input_letter

        expect(valid_month?(builder.month, builder.mode)).to be false

        expect { builder.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { builder.month }.to('A')

        expect(valid_month?(builder.month, builder.mode)).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies too large a month' do
      it 'prompts for input again' do
        $stdin = invalid_input_high_number

        expect(valid_month?(builder.month, builder.mode)).to be false

        expect { builder.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { builder.month }.to('13')

        expect(valid_month?(builder.month, builder.mode)).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies a valid integer month' do
      it 'accepts the valid input' do
        $stdin = valid_input

        expect(valid_month?(builder.month, builder.mode)).to be false

        expect { builder.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { builder.month }.to(1)

        expect(valid_month?(builder.month, builder.mode)).to be true

        $stdin = STDIN
      end
    end

    context 'given the user indicates All mode' do
      it 'accepts the valid input' do
        $stdin = valid_input_all_mode

        expect(valid_month?(builder.month, builder.mode)).to be false

        expect { builder.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { builder.month }.to(AppConstants::MODES[:ALL])

        expect(valid_month?(builder.month, builder.mode)).to be true

        $stdin = STDIN
      end
    end
  end

  context 'given proper inputs' do
    before :all do
      @output_dir = TestConstants::OUTPUT[:DIRECTORY]
    end

    after :all do
      `rm -rf #{@output_dir}`
    end

    context 'given build_file is executed with a month' do
      it 'prints january 1st' do
        builder = LogBuilder.new(TestConstants::CONFIG_FILES[:TEST_PATH], 'DO', 2020, 1, @output_dir)
        output = builder.build_file
        january_1st = output.find { |day| day.year == 2020 && day.month == 1 && day.month_day == 1 }

        expect(january_1st).to_not be_nil
      end
    end

    context 'given build_file is executed without a month' do
      it 'prints january 1st' do
        builder = LogBuilder.new(TestConstants::CONFIG_FILES[:TEST_PATH], 'DO', 2020, 1, @output_dir)
        output = builder.build_file
        january_1st = output.find { |day| day.year == 2020 && day.month == 1 && day.month_day == 1 }

        expect(january_1st).to_not be_nil
      end
    end
  end
end
