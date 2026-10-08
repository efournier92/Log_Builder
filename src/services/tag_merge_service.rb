require_relative '../services/task_printer_service'
require_relative '../constants/config_constants'

class TagMergeService
  def self.roots_from_template(template)
    return [] if template.nil?
    return [to_node(template, nil)] if template.is_a?(String)
    return template.map { |element| to_node(element, nil) } if template.is_a?(Array)

    template.map { |name, value| to_node(name, value) }
  end

  def self.canonical_roots(value)
    return [to_node(value, nil)] if value.is_a?(String)

    value
  end

  def self.order_roots(roots, tag_order)
    if roots.any? { |node| node[:name] == ConfigConstants::TAG_ORDER_MARKER }
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG],
                   "tag name is reserved: #{ConfigConstants::TAG_ORDER_MARKER}")
    end

    return roots if tag_order.nil?
    unless tag_order.is_a?(Array)
      raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config must be a list')
    end
    return roots if tag_order.empty?

    positions = {}
    unlisted_rank = tag_order.length
    tag_order.each_with_index do |entry, index|
      unless entry.is_a?(String)
        raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], 'tag_order_config entries must be strings')
      end
      if positions.key?(entry)
        raise format(ConfigConstants::ERRORS[:INVALID_CONFIG], "duplicate tag_order_config entry: #{entry}")
      end

      positions[entry] = index
      unlisted_rank = index if entry == ConfigConstants::TAG_ORDER_MARKER
    end

    roots.each_with_index
         .sort_by { |node, index| [positions.fetch(node[:name], unlisted_rank), index] }
         .map(&:first)
  end

  def self.add_roots(existing, incoming)
    incoming.reverse_each do |node|
      index = existing.index { |root| root[:name] == node[:name] }
      if index
        existing[index] = merge_nodes(existing[index], node)
      else
        existing.unshift(node)
      end
    end
    existing
  end

  def self.merge_nodes(existing, incoming)
    if existing[:leaf] && incoming[:leaf]
      existing
    elsif existing[:leaf]
      node(incoming[:name], [existing] + incoming[:children])
    elsif incoming[:leaf]
      node(existing[:name], [incoming] + existing[:children])
    else
      node(existing[:name], merge_children(existing[:children], incoming[:children]))
    end
  end

  def self.merge_children(existing, incoming)
    result = []
    unconsumed = existing.dup

    incoming.each do |child|
      index = result.index { |node| node[:name] == child[:name] }
      if index
        result[index] = merge_nodes(result[index], child)
        next
      end

      match_index = unconsumed.index { |node| node[:name] == child[:name] }
      matched = match_index ? unconsumed.delete_at(match_index) : nil
      result << (matched ? merge_nodes(matched, child) : child)
    end

    unconsumed.each do |node|
      result << node unless result.any? { |present| present[:name] == node[:name] }
    end

    result
  end

  def self.render(roots, config_file)
    roots.map do |root|
      tree = root[:leaf] ? [root[:name]] : { root[:name] => printable_children(root[:children]) }
      TaskPrinterService.new(config_file).print(tree)
    end.join
  end

  def self.printable_children(children)
    return children.map { |child| child[:name] } if children.all? { |child| child[:leaf] }

    children.each_with_object({}) do |child, tree|
      tree[child[:name]] = child[:leaf] ? nil : printable_children(child[:children])
    end
  end

  def self.to_node(name, value)
    if value.nil?
      leaf_node(name)
    elsif value.is_a?(Hash)
      node(name, value.map { |child_name, child_value| to_node(child_name, child_value) })
    elsif value.is_a?(Array)
      node(name, value.map { |element| to_node(element, nil) })
    else
      node(name, [leaf_node(value.to_s)])
    end
  end

  # Explicit hash values are required by the Ruby 2.6 runtime floor, which lacks value omission.
  # rubocop:disable Style/HashSyntax
  def self.node(name, children)
    { name: name, leaf: false, children: children.freeze }.freeze
  end

  def self.leaf_node(name)
    { name: name, leaf: true, children: [].freeze }.freeze
  end
  # rubocop:enable Style/HashSyntax
end
