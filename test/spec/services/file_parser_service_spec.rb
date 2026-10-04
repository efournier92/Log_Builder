require './src/services/file_parser_service'

describe FileParser do
  before :each do
    @parser = FileParser.new
  end

  describe '#get_date_hash_from_do_file' do
    context 'given a normal two-day document' do
      it 'returns a hash keyed by date with the block content' do
        file_contents = "## 2020-01-01\n\n```text\nDay one content\n```\n\n" \
                        "## 2020-01-02\n\n```text\nDay two content\n```\n\n"

        output = @parser.get_date_hash_from_do_file(file_contents)

        expected = {
          '2020-01-01' => "\n\n```text\nDay one content",
          '2020-01-02' => "\n\n```text\nDay two content"
        }

        expect(output).to eq(expected)
      end
    end

    context 'given an empty string' do
      it 'returns an empty hash' do
        output = @parser.get_date_hash_from_do_file('')

        expect(output).to eq({})
      end
    end

    # it 'does not hang' do
    #   TODO: the while loop never terminates when next_new_line is nil
    # end

    context 'given a single-day document' do
      pending 'returns only the block content as the value' do
        file_contents = "## 2020-01-01\n\n```text\nA\n```\n\n"

        output = @parser.get_date_hash_from_do_file(file_contents)

        expect(output).to eq('2020-01-01' => 'A')
      end
    end
  end

  describe '#get_date_hash_from_lg_file' do
    context 'given a normal two-section document' do
      it 'returns a hash keyed by heading with stripped section bodies' do
        file_contents = "Header\n## 2020-01-01 | Alpha\nBody A line\n\n" \
                        "## 2020-01-02 | Beta\nBody B line\n"

        output = @parser.get_date_hash_from_lg_file(file_contents)

        expected = {
          '## 2020-01-01 | Alpha' => 'Body A line',
          '## 2020-01-02 | Beta' => 'Body B line'
        }

        expect(output).to eq(expected)
      end
    end

    context 'given an empty string' do
      it 'returns an empty hash' do
        output = @parser.get_date_hash_from_lg_file('')

        expect(output).to eq({})
      end
    end

    context 'given a section whose heading has no following newline' do
      it 'skips the section' do
        file_contents = "Header\n## 2020-01-01 | Alpha\nBody A\n\n## 2020-01-02 | Beta"

        output = @parser.get_date_hash_from_lg_file(file_contents)

        expect(output).to eq('## 2020-01-01 | Alpha' => 'Body A')
      end
    end
  end
end
