# frozen_string_literal: true

module Proof
  class KdlMembers
    def initialize(table, refusal:)
      @table = table
      @refusal = refusal
    end

    def of_properties(node)
      pairs = node.properties.filter_map { |name, _value| pair(name, node) }
      pairs.to_h
    end

    def of_children(node)
      pairs = node.children.filter_map { |child| pair(child.name, child) }
      pairs.to_h
    end

    private def pair(name, giver)
      # A value is refused at the line of the node that gives it.
      member, build = @table[name.to_sym]
      [member, @refusal.checking(giver) { build.call(giver) }] if build
    end
  end
end
