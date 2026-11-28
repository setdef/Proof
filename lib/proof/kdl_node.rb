# frozen_string_literal: true

module Proof
  class KdlNode < Data.define(:name, :arguments, :properties, :children, :line)
    def self.each_after_first(nodes)
      nodes.each_with_index { |node, index| yield(node, first_named(node.name, nodes.take(index))) }
    end

    def each_child(&)
      KdlNode.each_after_first(children, &)
    end

    def named(name)
      children.select { |child| child.name == name }
    end

    def pairs_named(name)
      named(name).flat_map { |child| child.arguments.product([child]) }
    end

    def self.first_named(name, nodes)
      nodes.find { |node| node.name == name }
    end
    private_class_method(:first_named)

    # @dynamic name, arguments, properties, children, line, initialize
  end
end
