require './src/modules/log_sketcher'
require './src/constants/app_constants'
require './test/constants/test_constants'

describe LogSketcher do
  describe '#prompt_for_mode_input' do
    context 'given the user supplies a valid mode' do
      let(:input) { StringIO.new(AppConstants::MODES[:DO]) }

      it 'prompts for mode input' do
        sketcher = LogSketcher.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil)

        expect(sketcher.valid_mode?).to be false

        $stdin = input
        expect { sketcher.prompt_for_mode_input }.to output(
          AppConstants::INPUT_PROMPTS[:MODE]
        ).to_stdout.and change { sketcher.mode }.to(AppConstants::MODES[:DO])

        $stdin = STDIN

        expect(sketcher.valid_mode?).to be true
      end
    end

    context 'given the user supplies an invalid mode' do
      let(:invalid_input) { StringIO.new('DUN') }
      let(:valid_input) { StringIO.new(AppConstants::MODES[:DO]) }
      let(:sketcher) { LogSketcher.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil) }

      it 'prompts for mode input again after invalid input' do
        $stdin = invalid_input

        expect(sketcher.valid_mode?).to be false

        expect { sketcher.prompt_for_mode_input }.to output(
          AppConstants::INPUT_PROMPTS[:MODE]
        ).to_stdout.and change { sketcher.mode }.to('DUN')

        expect(sketcher.valid_mode?).to be false
      end

      it 'accepts valid input' do
        $stdin = valid_input

        expect { sketcher.prompt_for_mode_input }.to output(
          AppConstants::INPUT_PROMPTS[:MODE]
        ).to_stdout.and change { sketcher.mode }.to(AppConstants::MODES[:DO])

        expect(sketcher.valid_mode?).to be true
      end
    end
  end

  describe '#prompt_for_year_input' do
    context 'given the user supplies an invalid year, then a valid one' do
      let(:sketcher) { LogSketcher.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil) }
      let(:invalid_input_zero) { StringIO.new('0') }
      let(:invalid_input_negative) { StringIO.new('-1') }
      let(:invalid_input_letter) { StringIO.new('a') }
      let(:valid_input) { StringIO.new('2024') }

      it 'prompts for year input again after zero input' do
        $stdin = invalid_input_zero

        expect(sketcher.valid_year?).to be false

        expect { sketcher.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { sketcher.year }.to(0)

        expect(sketcher.valid_year?).to be false
      end

      it 'prompts for year input again after negative input' do
        $stdin = invalid_input_negative

        expect(sketcher.valid_year?).to be false

        expect { sketcher.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { sketcher.year }.to(-1)

        expect(sketcher.valid_year?).to be false

        $stdin = STDIN
      end

      it 'prompts for year input again after letter input' do
        $stdin = invalid_input_letter

        expect(sketcher.valid_year?).to be false

        expect { sketcher.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { sketcher.year }.to('a'.to_i)

        expect(sketcher.valid_year?).to be false

        $stdin = STDIN
      end

      it 'accepts valid input' do
        $stdin = valid_input

        expect(sketcher.valid_year?).to be false

        expect { sketcher.prompt_for_year_input }.to output(
          AppConstants::INPUT_PROMPTS[:YEAR]
        ).to_stdout.and change { sketcher.year }.to(2024)

        expect(sketcher.valid_year?).to be true

        $stdin = STDIN
      end
    end
  end

  describe '#prompt_for_month_input' do
    let(:sketcher) { LogSketcher.new(TestConstants::CONFIG_FILES[:TEST_PATH], '', nil, nil, nil) }
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

        expect(sketcher.valid_month?).to be false

        expect { sketcher.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout

        expect(sketcher.valid_month?).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies a negative month' do
      it 'prompts for input again' do
        $stdin = invalid_input_negative

        expect(sketcher.valid_month?).to be false

        expect { sketcher.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { sketcher.month }.to('-1')

        expect(sketcher.valid_month?).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies a letter month' do
      it 'prompts for input again' do
        $stdin = invalid_input_letter

        expect(sketcher.valid_month?).to be false

        expect { sketcher.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { sketcher.month }.to('A')

        expect(sketcher.valid_month?).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies too large a month' do
      it 'prompts for input again' do
        $stdin = invalid_input_high_number

        expect(sketcher.valid_month?).to be false

        expect { sketcher.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { sketcher.month }.to('13')

        expect(sketcher.valid_month?).to be false

        $stdin = STDIN
      end
    end

    context 'given the user supplies a valid integer month' do
      it 'accepts the valid input' do
        $stdin = valid_input

        expect(sketcher.valid_month?).to be false

        expect { sketcher.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { sketcher.month }.to(1)

        expect(sketcher.valid_month?).to be true

        $stdin = STDIN
      end
    end

    context 'given the user indicates All mode' do
      it 'accepts the valid input' do
        $stdin = valid_input_all_mode

        expect(sketcher.valid_month?).to be false

        expect { sketcher.prompt_for_month_input }.to output(
          AppConstants::INPUT_PROMPTS[:MONTH]
        ).to_stdout.and change { sketcher.month }.to(AppConstants::MODES[:ALL])

        expect(sketcher.valid_month?).to be true

        $stdin = STDIN
      end
    end
  end

  context 'given print_file is executed with a month' do
    before :all do
      @output_dir = TestConstants::OUTPUT[:DIRECTORY]
    end

    after :all do
      `rm -rf #{@output_dir}`
    end

    it 'prints january 1st' do
      sketcher = LogSketcher.new(TestConstants::CONFIG_FILES[:TEST_PATH], 'DO', 2020, 1, @output_dir)
      output = sketcher.print_file
      january_1st = output[0].days.find { |day| day.year == 2020 && day.month == 1 && day.month_day == 1 }

      expect(january_1st).to_not be_nil
    end
  end

  context 'given print_file is executed without a month' do
    it 'prints january 1st' do
      sketcher = LogSketcher.new(TestConstants::CONFIG_FILES[:TEST_PATH], 'DO', 2020, 1, @output_dir)
      output = sketcher.print_file
      january_1st = output[0].days.find { |day| day.year == 2020 && day.month == 1 && day.month_day == 1 }

      expect(january_1st).to_not be_nil
    end
  end
end
