# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class KdlNode < Data.define(:name, :arguments, :properties, :children, :line)
    # steep:ignore:end
    def arguments_only?
      properties.empty? && children.empty?
    end

    def each_child
      children.each_with_index { |child, index| yield(child, first_before(index)) }
    end

    def children_by_name
      children.to_h { |child| [child.name, child] }
    end

    private def first_before(index)
      name = children[index].name
      children.take(index).find { |earlier| earlier.name == name }
    end
  end
end
