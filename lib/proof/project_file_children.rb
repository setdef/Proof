# frozen_string_literal: true

module Proof
  class ProjectFileChildren
    NAMES = %w[os label artifact cache].freeze
    public_constant(:NAMES)

    def initialize(refusal:)
      @refusal = refusal
    end

    def refuse_mistakes_in(node)
      node.children.each { |child| @refusal.unknown_child(node, child) unless NAMES.include?(child.name) }
    end
  end
end
