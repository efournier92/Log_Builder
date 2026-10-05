require './src/services/tag_merge_service'
require './src/constants/config_constants'
require './test/constants/test_constants'

def leaf_node(name)
  { name:, leaf: true, children: [] }
end

def internal_node(name, children)
  { name:, leaf: false, children: }
end

def child_names(node)
  node[:children].map { |child| child[:name] }
end

describe TagMergeService do
  describe '.roots_from_template' do
    it 'returns one leaf node for a String template' do
      roots = TagMergeService.roots_from_template('Task_Name')

      expect(roots).to eq([leaf_node('Task_Name')])
    end

    it 'splits a multi-key Hash into one node per key' do
      roots = TagMergeService.roots_from_template('One' => nil, 'Two' => nil)

      expect(roots).to eq([leaf_node('One'), leaf_node('Two')])
    end

    it 'turns an Array template into one leaf node per element' do
      roots = TagMergeService.roots_from_template(%w[Alpha Beta])

      expect(roots).to eq([leaf_node('Alpha'), leaf_node('Beta')])
    end

    it 'maps a nil value to a leaf named by the key' do
      roots = TagMergeService.roots_from_template('Milligrams' => nil)

      expect(roots).to eq([leaf_node('Milligrams')])
    end

    it 'maps a scalar hash value to an internal with a single leaf child' do
      roots = TagMergeService.roots_from_template('Milligrams' => 4000)

      expect(roots).to eq([internal_node('Milligrams', [leaf_node('4000')])])
    end

    it 'returns an empty array for a nil template' do
      expect(TagMergeService.roots_from_template(nil)).to eq([])
    end
  end

  describe '.canonical_roots' do
    it 'returns one leaf node for a String' do
      expect(TagMergeService.canonical_roots('Test_Tag')).to eq([leaf_node('Test_Tag')])
    end

    it 'returns an already-canonical Array unchanged' do
      roots = [internal_node('Body', [leaf_node('Ears')])]

      expect(TagMergeService.canonical_roots(roots)).to be(roots)
    end
  end

  describe '.order_roots' do
    def names(roots)
      roots.map { |node| node[:name] }
    end

    it 'returns the input unchanged for a nil list' do
      roots = [leaf_node('Alpha')]

      expect(TagMergeService.order_roots(roots, nil)).to be(roots)
    end

    it 'returns the input unchanged for an empty list' do
      roots = [leaf_node('Alpha')]

      expect(TagMergeService.order_roots(roots, [])).to be(roots)
    end

    it 'places a listed root at its list index' do
      roots = [leaf_node('Body'), leaf_node('Alpha')]

      result = TagMergeService.order_roots(roots, ['Alpha', '~OTHER~', 'Body'])

      expect(names(result)).to eq(%w[Alpha Body])
    end

    it 'places an unlisted root at the marker index between two listed roots' do
      roots = [leaf_node('Body'), leaf_node('Zeta'), leaf_node('Alpha')]

      result = TagMergeService.order_roots(roots, ['Alpha', '~OTHER~', 'Body'])

      expect(names(result)).to eq(%w[Alpha Zeta Body])
    end

    it 'keeps the incoming relative order of all unlisted roots at the marker' do
      roots = [leaf_node('Alpha'), leaf_node('Zeta')]

      result = TagMergeService.order_roots(roots, ['~OTHER~', 'Body'])

      expect(names(result)).to eq(%w[Alpha Zeta])
    end

    it 'puts unlisted roots after all listed roots when the marker is absent' do
      roots = [leaf_node('Zeta'), leaf_node('Alpha'), leaf_node('Holiday'), leaf_node('Body')]

      result = TagMergeService.order_roots(roots, %w[Holiday Body])

      expect(names(result)).to eq(%w[Holiday Body Zeta Alpha])
    end

    it 'puts unlisted roots before all listed roots when the marker is first' do
      roots = [leaf_node('Body'), leaf_node('Zeta'), leaf_node('Alpha')]

      result = TagMergeService.order_roots(roots, ['~OTHER~', 'Body'])

      expect(names(result)).to eq(%w[Zeta Alpha Body])
    end

    it 'advances listed roots that appear after the marker past the unlisted block' do
      roots = [leaf_node('Zeta'), leaf_node('Body'), leaf_node('Alpha')]

      result = TagMergeService.order_roots(roots, ['~OTHER~', 'Body'])

      expect(names(result)).to eq(%w[Zeta Alpha Body])
    end

    it 'ignores a listed tag that is absent from the roots' do
      roots = [leaf_node('Alpha'), leaf_node('Body')]

      result = TagMergeService.order_roots(roots, ['Holiday', '~OTHER~', 'Body'])

      expect(names(result)).to eq(%w[Alpha Body])
    end

    it 'is idempotent' do
      roots = [leaf_node('Body'), leaf_node('Zeta'), leaf_node('Holiday')]
      order = ['Holiday', '~OTHER~', 'Body']

      once = TagMergeService.order_roots(roots, order)
      twice = TagMergeService.order_roots(once, order)

      expect(names(twice)).to eq(names(once))
    end

    it 'does not mutate the input array' do
      roots = [leaf_node('Body'), leaf_node('Zeta'), leaf_node('Holiday')]
      snapshot = Marshal.load(Marshal.dump(roots))

      TagMergeService.order_roots(roots, ['Holiday', '~OTHER~', 'Body'])

      expect(roots).to eq(snapshot)
    end

    it 'raises when the list is not an Array' do
      expect { TagMergeService.order_roots([leaf_node('Alpha')], {}) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config must be a list')
      )
    end

    it 'raises when the list is the scalar false' do
      expect { TagMergeService.order_roots([leaf_node('Alpha')], false) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config must be a list')
      )
    end

    it 'raises when an entry is not a string' do
      expect { TagMergeService.order_roots([leaf_node('Alpha')], ['Alpha', 3]) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config entries must be strings')
      )
    end

    it 'raises on a repeated tag name' do
      expect { TagMergeService.order_roots([leaf_node('Alpha')], %w[Holiday Holiday]) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'duplicate tag_order_config entry: Holiday')
      )
    end

    it 'raises on a repeated marker' do
      expect { TagMergeService.order_roots([leaf_node('Alpha')], ['~OTHER~', '~OTHER~']) }.to raise_error(
        format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'duplicate tag_order_config entry: ~OTHER~')
      )
    end

    it 'places a merged root in its ordered slot after add_roots' do
      roots = TagMergeService.add_roots([], [leaf_node('Holiday'), leaf_node('Body')])
      roots = TagMergeService.add_roots(roots, [leaf_node('Holiday')])

      result = TagMergeService.order_roots(roots, ['Body', '~OTHER~', 'Holiday'])

      expect(names(result)).to eq(%w[Body Holiday])
    end
  end

  describe '.add_roots' do
    it 'prepends a new root to the front' do
      existing = [leaf_node('Zeta')]

      result = TagMergeService.add_roots(existing, [leaf_node('Alpha')])

      expect(result.map { |node| node[:name] }).to eq(%w[Alpha Zeta])
    end

    it 'preserves the order of a two-root incoming block' do
      result = TagMergeService.add_roots([], [leaf_node('Alpha'), leaf_node('Beta')])

      expect(result.map { |node| node[:name] }).to eq(%w[Alpha Beta])
    end

    it 'merges two same-named internal roots and keeps the existing slot' do
      existing = [leaf_node('Alpha'), internal_node('Body', [leaf_node('X')]), leaf_node('Zeta')]
      incoming = [internal_node('Body', [leaf_node('Y')])]

      result = TagMergeService.add_roots(existing, incoming)

      expect(result.map { |node| node[:name] }).to eq(%w[Alpha Body Zeta])
      expect(child_names(result[1])).to eq(%w[Y X])
    end

    it 'does not mutate incoming or the nodes it holds' do
      incoming = TagMergeService.roots_from_template('Body' => { 'Ears' => %w[Drops] })
      snapshot = Marshal.load(Marshal.dump(incoming))
      existing = [internal_node('Body', [leaf_node('Other')])]

      TagMergeService.add_roots(existing, incoming)

      expect(incoming).to eq(snapshot)
    end

    it 'dedupes two identical leaf roots' do
      result = TagMergeService.add_roots([leaf_node('Same')], [leaf_node('Same')])

      expect(result).to eq([leaf_node('Same')])
    end

    it 'keeps two different-text leaf roots as separate nodes' do
      result = TagMergeService.add_roots([leaf_node('Alpha')], [leaf_node('Beta')])

      expect(result.map { |node| node[:name] }).to eq(%w[Beta Alpha])
    end

    it 'resolves an internal versus leaf name collision with the internal kept' do
      existing = [internal_node('Body', [leaf_node('Existing')])]
      incoming = [leaf_node('Body')]

      result = TagMergeService.add_roots(existing, incoming)

      expect(result[0][:leaf]).to be false
      expect(child_names(result[0])).to eq(%w[Body Existing])
    end

    it 'resolves the reverse order with the internal kept and the leaf prepended' do
      existing = [leaf_node('Body')]
      incoming = [internal_node('Body', [leaf_node('Incoming')])]

      result = TagMergeService.add_roots(existing, incoming)

      expect(result[0][:leaf]).to be false
      expect(child_names(result[0])).to eq(%w[Body Incoming])
    end

    it 'resolves an internal versus leaf collision at a nested level' do
      existing = [internal_node('Body', [leaf_node('Nested')])]
      incoming = [internal_node('Body', [internal_node('Nested', [leaf_node('Child')])])]

      result = TagMergeService.add_roots(existing, incoming)

      nested = result[0][:children][0]
      expect(nested[:leaf]).to be false
      expect(child_names(nested)).to eq(%w[Nested Child])
    end
  end

  describe '.merge_nodes' do
    it 'prepends incoming children before existing children and does not mutate either input' do
      a = internal_node('N', [leaf_node('X')])
      b = internal_node('N', [leaf_node('Y')])

      result = TagMergeService.merge_nodes(a, b)

      expect(child_names(result)).to eq(%w[Y X])
      expect(child_names(a)).to eq(%w[X])
      expect(child_names(b)).to eq(%w[Y])
    end
  end

  describe '.merge_children' do
    it 'recurses into a shared internal child and dedupes its exact leaves' do
      existing = [internal_node('N', [leaf_node('L1'), leaf_node('L2')])]
      incoming = [internal_node('N', [leaf_node('L2'), leaf_node('L3')])]

      result = TagMergeService.merge_children(existing, incoming)

      expect(result.length).to eq(1)
      expect(child_names(result[0])).to eq(%w[L2 L3 L1])
    end

    it 'dedupes an exact duplicate leaf across incoming and existing' do
      result = TagMergeService.merge_children([leaf_node('A')], [leaf_node('A')])

      expect(result).to eq([leaf_node('A')])
    end

    it 'keeps incoming children before existing children' do
      result = TagMergeService.merge_children([leaf_node('Vitamins_Take')], [leaf_node('Ears')])

      expect(result.map { |node| node[:name] }).to eq(%w[Ears Vitamins_Take])
    end
  end

  describe '.render' do
    let(:config_file) { TestConstants::CONFIG_FILES[:TEST_PATH] }

    it 'reproduces a two-level internal root' do
      roots = [internal_node('Level_1', [leaf_node('Level_2')])]

      expect(TagMergeService.render(roots, config_file)).to eq("Level_1(\n  Level_2,\n),\n")
    end

    it 'reproduces a leaf root' do
      expect(TagMergeService.render([leaf_node('Task_Name')], config_file)).to eq("Task_Name,\n")
    end

    it 'returns an empty string for an empty roots array' do
      expect(TagMergeService.render([], config_file)).to eq('')
    end

    it 'renders literal composed placeholders with no extra stdout' do
      children = [
        leaf_node('{{TASK.Composed_Level_2a}}'),
        leaf_node('{{TASK.Composed_Level_2b}}')
      ]
      roots = [internal_node('Composed_Task', children)]

      rendered = nil
      expect { rendered = TagMergeService.render(roots, config_file) }.to_not output.to_stdout

      expect(rendered).to eq(
        "Composed_Task(\n  {{TASK.Composed_Level_2a}},\n  {{TASK.Composed_Level_2b}},\n),\n"
      )
    end
  end

  describe 'multi-day isolation' do
    it 'keeps two day trees independent when the same incoming nodes are reused' do
      incoming = TagMergeService.roots_from_template('Body' => { 'Ears' => %w[Drops] })
      day_one = TagMergeService.add_roots([], incoming)
      day_two = TagMergeService.add_roots([], incoming)
      snapshot_two = Marshal.load(Marshal.dump(day_two))

      extra = TagMergeService.roots_from_template('Body' => { 'Ears' => %w[Camera] })
      TagMergeService.add_roots(day_one, extra)

      expect(day_two).to eq(snapshot_two)
      expect(child_names(day_two[0][:children][0])).to eq(%w[Drops])
      expect(child_names(day_one[0][:children][0])).to eq(%w[Camera Drops])
    end
  end

  describe 'worked scenario from DuplicateTags_Example' do
    it 'unions four Body contributions into one root in child order Ears, Vitamins_Take, Vc' do
      drops = TagMergeService.roots_from_template('Body' => { 'Ears' => %w[Drops_CarbamidePeroxide_Apply] })
      drops_again = TagMergeService.roots_from_template('Body' => { 'Ears' => %w[Drops_CarbamidePeroxide_Apply] })
      clean = TagMergeService.roots_from_template(
        'Body' => { 'Ears' => %w[Drops_CarbamidePeroxide_Apply Camera_Wax_Remove] }
      )
      vitamins = TagMergeService.roots_from_template(
        'Body' => { 'Vitamins_Take' => %w[Pills], 'Vc' => %w[Bo Alc] }
      )

      roots = []
      [vitamins, clean, drops_again, drops].each do |contribution|
        roots = TagMergeService.add_roots(roots, contribution)
      end

      expect(roots.length).to eq(1)
      body = roots[0]
      expect(body[:leaf]).to be false
      expect(child_names(body)).to eq(%w[Ears Vitamins_Take Vc])
      expect(child_names(body[:children][0])).to eq(%w[Drops_CarbamidePeroxide_Apply Camera_Wax_Remove])
    end
  end
end
