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
      node.named(name).each { |child| refuse_all(child, what) }
    end

    private def refuse_all(child, what)
      child.arguments.each { |value| refuse(child, what, value) }
    end
  end
end
