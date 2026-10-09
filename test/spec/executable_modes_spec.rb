# frozen_string_literal: true

require 'open3'

describe 'tracked file modes' do
  root = File.expand_path('../..', __dir__)

  def tracked_entries(root)
    entries, _stderr, status =
      Open3.capture3('git', '-c', 'core.quotePath=false', 'ls-files', '-s', chdir: root)
    expect(status.exitstatus).to eq(0)
    entries.each_line.map { |line| line.chomp.split(/\s+/, 4) }
  end

  def shebang?(root, path)
    File.binread(File.join(root, path), 2) == '#!'
  rescue SystemCallError
    raise "tracked file missing from the working tree: #{path}"
  end

  it 'commits every shebang file with mode 100755' do
    offenders = tracked_entries(root).filter_map do |mode, _sha, _stage, path|
      next unless shebang?(root, path)

      path unless mode == '100755'
    end

    expect(offenders).to be_empty, "shebang files must be committed mode 100755: #{offenders.join(', ')}"
  end

  it 'commits every non-shebang regular file with mode 100644' do
    offenders = tracked_entries(root).filter_map do |mode, _sha, _stage, path|
      next unless mode.start_with?('100')
      next if shebang?(root, path)

      path unless mode == '100644'
    end

    expect(offenders).to be_empty, "non-shebang files must be committed mode 100644: #{offenders.join(', ')}"
  end
end
