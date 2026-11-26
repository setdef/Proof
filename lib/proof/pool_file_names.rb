# frozen_string_literal: true

module Proof
  class PoolFileNames
    BLANK = -> (value) { value.is_a?(String) && value.match?(/\A[[:space:]]*\z/) }
    private_constant(:BLANK)

    def initialize(refusal:)
      @refusal = refusal
    end

    def refuse(node, what, value)
      @refusal.blank_name(node, what, value) if BLANK.call(value)
    end

    def refuse_children(node, name, what)
      node.pairs_named(name).each { |value, child| refuse(child, what, value) }
    end
  end
end
