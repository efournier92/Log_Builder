class FileParser
  NEXT_NEW_LINE_PATTERN = "\n".freeze
  DATE_LINE_START_PATTERN = '## '.freeze
  DO_BLOCK_START_PATTERN = "\n\n```text\n".freeze
  DO_BLOCK_END_PATTERN = "\n```\n\n".freeze
  DO_BLOCK_CRAP_PATTERN = "\n\n```\n".freeze
  DATE_REGEX = /(\d{4}-\d{2}-\d{2})/.freeze

  def get_date_hash_from_do_file(file_contents)
    output = {}

    next_item_exists = true
    while next_item_exists == true
      next_date_line = file_contents.index(DATE_LINE_START_PATTERN)

      next_item_exists = !next_date_line.nil?

      next_new_line = file_contents.index(NEXT_NEW_LINE_PATTERN)

      next if next_date_line.nil? || next_new_line.nil?

      date_line = file_contents.slice!(next_date_line, next_new_line)
      date = date_line.match(DATE_REGEX)

      date = date[0] unless date.nil? || date[0].nil?

      next_do_block_start = file_contents.index(DO_BLOCK_START_PATTERN)
      next_do_block_end = file_contents.index("\n```\n\n")

      do_block = file_contents.slice!(next_do_block_start, next_do_block_end)
      file_contents.slice!(DO_BLOCK_END_PATTERN)

      do_block.slice!(DO_BLOCK_CRAP_PATTERN)

      output[date] = do_block
    end

    output
  end

  def get_date_hash_from_lg_file(file_contents)
    output = {}

    while (next_date_line = file_contents.index("\n## "))
      next_new_line = file_contents.index("\n", next_date_line + 1)
      break if next_new_line.nil?

      date_line = file_contents[next_date_line...next_new_line]
      key = date_line.strip

      next_section_start = file_contents.index("\n## ", next_new_line + 1)
      section_end = next_section_start || file_contents.length
      section_content = file_contents[next_new_line...section_end]

      output[key] = section_content.strip

      file_contents = file_contents[section_end..]
    end

    output
  end
end
