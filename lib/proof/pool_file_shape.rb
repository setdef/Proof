# frozen_string_literal: true

module Proof
  class PoolFileShape
    def initialize(refusal:)
      @refusal = refusal
    end

    def check(node)
      form = PoolFileForms.of(node)
      @refusal.node_arguments(node, node.arguments.size) unless form.takes?(node)
      refuse_properties(node, form)
      refuse_children(node, form)
    end

    private def refuse_properties(node, form)
      stray = form.stray_property(node)
      refuse_stray(node, stray) if stray
      missing = form.missing_property(node)
      @refusal.missing(node, "property", missing) if missing
    end

    private def refuse_children(node, form)
      node.each_child { |child, first| refuse_child(node, child, first) }
      missing = form.missing_child(node)
      @refusal.missing(node, "child", missing) if missing
    end

    private def refuse_child(parent, child, first)
      form = PoolFileForms.of(parent)
      refuse_unknown(parent, child) if form.lacks_child?(child)
      @refusal.repeated_child(child, first) if first && !PoolFileForms.of(child).repeatable
      check(child)
    end

    private def refuse_stray(node, property)
      children = PoolFileForms.of(node).children
      return @refusal.property_that_is_a_child(node, property) if children.include?(property.to_sym)

      @refusal.unknown_property(node, property)
    end

    private def refuse_unknown(parent, child)
      properties = PoolFileForms.of(parent).properties
      return @refusal.child_that_is_a_property(parent, child) if properties.include?(child.name.to_sym)

      @refusal.unknown_child(parent, child)
    end
  end
end
