require 'stringio'
require 'tmpdir'
require './src/services/printer_service'
require './src/services/config_reader_service'
require './src/constants/config_constants'
require './src/models/year'

describe PrinterService do
  before :each do
    @printer = PrinterService.new('./test/test_config.yml')
  end

  describe '#date_line' do
    context 'given a day' do
      it 'formats the date line with a zero padded date and the day name' do
        day = double('day', year: 2020, month: 3, month_day: 7, name: 'Saturday')

        expect(@printer.date_line(day)).to eq('## 2020-03-07 | Saturday')
      end
    end
  end

  describe '#do_file_name' do
    context 'given a year and a month' do
      it 'returns the monthly do file name' do
        printer = PrinterService.new('./test/test_config.yml', './out')

        expect(printer.do_file_name(2020, 1)).to eq('./out/DO_2020_01.md')
      end
    end

    context 'given only a year' do
      it 'returns the yearly do file name' do
        printer = PrinterService.new('./test/test_config.yml', './out')

        expect(printer.do_file_name(2020)).to eq('./out/DO_2020.md')
      end
    end
  end

  describe '#lg_file_name' do
    context 'given a year' do
      it 'returns the yearly lg file name' do
        printer = PrinterService.new('./test/test_config.yml', './out')

        expect(printer.lg_file_name(2020)).to eq('./out/LG_2020.md')
      end
    end
  end

  describe '#make_out_dir' do
    context 'given a missing output directory' do
      it 'creates the directory' do
        Dir.mktmpdir do |tmp_dir|
          out_dir = File.join(tmp_dir, 'nested', 'output')
          printer = PrinterService.new('./test/test_config.yml', out_dir)

          printer.make_out_dir

          expect(File.directory?(out_dir)).to be true
        end
      end
    end
  end

  describe '#print_tasks' do
    context 'given a day with tasks' do
      it 'writes the markdown block to the output stream' do
        day = double('day', year: 2020, month: 1, month_day: 1, name: 'Monday', tasks: 'TaskOne')
        out_file = StringIO.new

        @printer.print_tasks(out_file, day)

        expected = "## 2020-01-01 | Monday\n\n```text\nTaskOne\n```\n\n"
        expect(out_file.string).to eq(expected)
      end
    end
  end

  describe '#print_do_year' do
    context 'given a year of days' do
      it 'writes every day to the yearly do file' do
        Dir.mktmpdir do |tmp_dir|
          printer = PrinterService.new('./test/test_config.yml', tmp_dir)
          days = [
            double('day', year: 2020, month: 1, month_day: 1, name: 'Monday', tasks: 'TaskOne'),
            double('day', year: 2020, month: 2, month_day: 1, name: 'Saturday', tasks: 'TaskTwo')
          ]
          year = double('year', year_number: 2020, days:)

          printer.print_do_year(year)

          expected = "## 2020-01-01 | Monday\n\n```text\nTaskOne\n```\n\n" \
                     "## 2020-02-01 | Saturday\n\n```text\nTaskTwo\n```\n\n"
          expect(File.read(File.join(tmp_dir, 'DO_2020.md'))).to eq(expected)
        end
      end
    end
  end

  describe '#print_do_month' do
    context 'given a year of days in different months' do
      it 'writes only the days in the requested month' do
        Dir.mktmpdir do |tmp_dir|
          printer = PrinterService.new('./test/test_config.yml', tmp_dir)
          days = [
            double('day', year: 2020, month: 1, month_day: 1, name: 'Monday', tasks: 'TaskOne'),
            double('day', year: 2020, month: 2, month_day: 1, name: 'Saturday', tasks: 'TaskTwo')
          ]
          year = double('year', year_number: 2020, days:)

          printer.print_do_month(year, 1)

          expected = "## 2020-01-01 | Monday\n\n```text\nTaskOne\n```\n\n"
          expect(File.read(File.join(tmp_dir, 'DO_2020_01.md'))).to eq(expected)
        end
      end
    end

    context 'given a prior year day in the same month' do
      it 'writes only the requested year and month' do
        Dir.mktmpdir do |tmp_dir|
          printer = PrinterService.new('./test/test_config.yml', tmp_dir)
          days = [
            double('day', year: 2019, month: 1, month_day: 1, name: 'Monday', tasks: 'OldTask'),
            double('day', year: 2020, month: 1, month_day: 1, name: 'Monday', tasks: 'NewTask')
          ]
          year = double('year', year_number: 2020, days:)

          printer.print_do_month(year, 1)

          expected = "## 2020-01-01 | Monday\n\n```text\nNewTask\n```\n\n"
          expect(File.read(File.join(tmp_dir, 'DO_2020_01.md'))).to eq(expected)
        end
      end
    end
  end

  describe '#print_lg' do
    context 'given a year of days' do
      it 'writes each day and its template to the yearly lg file' do
        Dir.mktmpdir do |tmp_dir|
          printer = PrinterService.new('./test/test_config.yml', tmp_dir)
          days = [double('day', year: 2020, month: 1, month_day: 1, name: 'Monday')]
          year = double('year', year_number: 2020, days:)

          printer.print_lg(year)

          content = File.read(File.join(tmp_dir, 'LG_2020.md'))
          expect(content).to include('## 2020-01-01 | Monday')
          expect(content).to include('#### Today')
        end
      end
    end
  end

  describe '#get_template_by_day' do
    context 'given a weekday without a configured override' do
      it 'returns the base plus weekday templates' do
        expected = ['', '### Do', '', '```text', '```', '', '### Notes', '', '#### Yesterday', '', '#### Today', '']

        expect(@printer.get_template_by_day('Tuesday')).to eq(expected)
      end
    end

    context 'given a weekend day without a configured override' do
      it 'returns the base plus weekend templates' do
        expected = ['', '### Do', '', '```text', '```', '', '']

        expect(@printer.get_template_by_day('Saturday')).to eq(expected)
      end
    end

    context 'given a day with a configured override' do
      it 'returns the base plus the configured day template' do
        expected = ['', '### Do', '', '```text', '```', '', '### Notes', '', '#### Last Friday', '', '#### Today', '']

        expect(@printer.get_template_by_day('Monday')).to eq(expected)
      end
    end
  end
end
