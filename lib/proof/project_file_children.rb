# frozen_string_literal: true

module Proof
  class ProjectFileChildren
    NAMES = %w[os label artifact cache].freeze
    public_constant(:NAMES)

    def initialize(refusal:)
      @refusal = refusal
    end

    def refuse_mistakes_in(node)
      node.each_child { |child, first| check(node, child, first) }
    end

    private def check(parent, child, first)
      refuse_unknown(parent, child)
      @refusal.repeated_child(child, first) if first
      refuse_shape(child)
    end

    private def refuse_unknown(parent, child)
      @refusal.unknown_child(parent, child) unless NAMES.include?(child.name)
    end

    private def refuse_shape(child)
      @refusal.child_without_arguments(child) if child.arguments.empty?
      @refusal.child_with_more(child) unless child.arguments_only?
    end
  end
end
