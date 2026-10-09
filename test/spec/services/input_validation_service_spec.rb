require './src/services/input_validation_service'
require './src/constants/app_constants'
require './test/constants/test_constants'

describe 'input_validation_service' do
  describe '#valid_config_file?' do
    context 'given an existing config file path' do
      it 'returns true' do
        expect(valid_config_file?(TestConstants::CONFIG_FILES[:TEST_PATH])).to be true
      end
    end

    context 'given a missing config file path' do
      it 'returns false' do
        expect(valid_config_file?(TestConstants::CONFIG_FILES[:FAKE_PATH])).to be false
      end
    end

    context 'given an non-String config file' do
      it 'returns false' do
        expect(valid_config_file?(nil)).to be false
      end
    end
  end

  describe '#valid_mode?' do
    context 'given DO mode' do
      it 'returns true' do
        expect(valid_mode?(AppConstants::MODES[:DO])).to be true
      end
    end

    context 'given LG mode' do
      it 'returns true' do
        expect(valid_mode?(AppConstants::MODES[:LG])).to be true
      end
    end

    context 'given another string' do
      it 'returns false' do
        expect(valid_mode?('DUN')).to be false
      end
    end

    context 'given nil' do
      it 'returns false' do
        expect(valid_mode?(nil)).to be false
      end
    end
  end

  describe '#valid_year_number?' do
    context 'given a positive numeric String' do
      it 'returns true' do
        expect(valid_year_number?('2020')).to be true
      end
    end

    context 'given a positive Integer' do
      it 'returns true' do
        expect(valid_year_number?(2020)).to be true
      end
    end

    context 'given zero as a String' do
      it 'returns false' do
        expect(valid_year_number?('0')).to be false
      end
    end

    context 'given a negative String' do
      it 'returns false' do
        expect(valid_year_number?('-5')).to be false
      end
    end

    context 'given nil' do
      it 'returns false' do
        expect(valid_year_number?(nil)).to be false
      end
    end

    context 'given an empty String' do
      it 'returns false' do
        expect(valid_year_number?('')).to be false
      end
    end

    context 'given a positive Float' do
      it 'returns true' do
        expect(valid_year_number?(20.5)).to be true
      end
    end
  end

  describe '#valid_month?' do
    context 'given LG mode and an invalid month' do
      it 'returns true' do
        expect(valid_month?('0', AppConstants::MODES[:LG])).to be true
      end
    end

    context 'given DO mode and a valid month number' do
      it 'returns true' do
        expect(valid_month?(1, AppConstants::MODES[:DO])).to be true
      end
    end

    context 'given DO mode and ALL' do
      it 'returns true' do
        expect(valid_month?(AppConstants::MODES[:ALL], AppConstants::MODES[:DO])).to be true
      end
    end

    context 'given DO mode and an invalid month' do
      it 'returns false' do
        expect(valid_month?('0', AppConstants::MODES[:DO])).to be false
      end
    end
  end

  describe '#valid_month_number?' do
    context 'given 1' do
      it 'returns true' do
        expect(valid_month_number?(1)).to be true
      end
    end

    context 'given 12' do
      it 'returns true' do
        expect(valid_month_number?(12)).to be true
      end
    end

    context 'given 0' do
      it 'returns false' do
        expect(valid_month_number?(0)).to be false
      end
    end

    context 'given 13' do
      it 'returns false' do
        expect(valid_month_number?(13)).to be false
      end
    end

    context 'given nil' do
      it 'returns false' do
        expect(valid_month_number?(nil)).to be false
      end
    end

    context 'given a numeric String' do
      it 'returns true' do
        expect(valid_month_number?('1')).to be true
      end
    end
  end

  describe '#valid_month_pattern?' do
    context 'given valid month strings' do
      it 'returns true for each of 1 through 12' do
        ('1'..'12').each do |month|
          expect(valid_month_pattern?(month)).to be true
        end
      end
    end

    context 'given "0"' do
      it 'returns false' do
        expect(valid_month_pattern?('0')).to be false
      end
    end

    context 'given "13"' do
      it 'returns false' do
        expect(valid_month_pattern?('13')).to be false
      end
    end

    context 'given "a"' do
      it 'returns false' do
        expect(valid_month_pattern?('a')).to be false
      end
    end

    context 'given nil' do
      it 'returns false' do
        expect(valid_month_pattern?(nil)).to be false
      end
    end

    context 'given an Integer' do
      it 'returns false' do
        expect(valid_month_pattern?(1)).to be false
      end
    end
  end

  describe '#print_month?' do
    context 'given a positive Integer' do
      it 'returns true' do
        expect(print_month?(1)).to be true
      end
    end

    context 'given zero' do
      it 'returns false' do
        expect(print_month?(0)).to be false
      end
    end

    context 'given nil' do
      it 'returns false' do
        expect(print_month?(nil)).to be false
      end
    end

    context 'given a numeric String' do
      it 'returns false' do
        expect(print_month?('1')).to be false
      end
    end

    context 'given a Float' do
      it 'returns false' do
        expect(print_month?(1.5)).to be false
      end
    end
  end

  describe '#sanitize_month' do
    context 'given ALL' do
      it 'returns ALL unchanged' do
        expect(sanitize_month(AppConstants::MODES[:ALL])).to eql(AppConstants::MODES[:ALL])
      end
    end

    context 'given a numeric String' do
      it 'returns an Integer' do
        expect(sanitize_month('5')).to eql(5)
      end
    end

    context 'given an Integer' do
      it 'returns the Integer unchanged' do
        expect(sanitize_month(5)).to eql(5)
      end
    end
  end

  describe '#lg_mode?' do
    context 'given LG' do
      it 'returns true' do
        expect(lg_mode?(AppConstants::MODES[:LG])).to be true
      end
    end

    context 'given DO' do
      it 'returns false' do
        expect(lg_mode?(AppConstants::MODES[:DO])).to be false
      end
    end
  end

  describe '#all_mode?' do
    context 'given ALL' do
      it 'returns true' do
        expect(all_mode?(AppConstants::MODES[:ALL])).to be true
      end
    end

    context 'given DO' do
      it 'returns false' do
        expect(all_mode?(AppConstants::MODES[:DO])).to be false
      end
    end
  end

  describe '#all_month?' do
    context 'given ALL' do
      it 'returns true' do
        expect(all_month?(AppConstants::MODES[:ALL])).to be true
      end
    end

    context 'given DO' do
      it 'returns false' do
        expect(all_month?(AppConstants::MODES[:DO])).to be false
      end
    end
  end

  describe '#valid_output_dir?' do
    context 'given a String' do
      it 'returns true' do
        expect(valid_output_dir?('./out')).to be true
      end
    end

    context 'given an empty String' do
      it 'returns false' do
        expect(valid_output_dir?('')).to be false
      end
    end

    context 'given nil' do
      it 'returns false' do
        expect(valid_output_dir?(nil)).to be false
      end
    end
  end
end
