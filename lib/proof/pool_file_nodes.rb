# frozen_string_literal: true

module Proof
  class PoolFileNodes
    TOP = %i[server retention limits defaults host repository].freeze
    private_constant(:TOP)

    def initialize(nodes:, refusal:)
      @nodes = nodes
      @refusal = refusal
      @shape = PoolFileShape.new(refusal:)
    end

    def check
      @nodes.each_with_index { |node, index| check_node(node, @nodes.take(index)) }
    end

    private def check_node(node, earlier)
      refuse_unknown(node)
      first = earlier.find { |same| same.name == node.name }
      @refusal.repeated_node(node, first) if first && !PoolFileForms.of(node).repeatable
      @shape.check(node)
    end

    private def refuse_unknown(node)
      @refusal.unknown_node(node) unless TOP.include?(node.name.to_sym)
    end
  end
end
