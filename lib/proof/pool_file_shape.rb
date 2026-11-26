# frozen_string_literal: true

module Proof
  class PoolFileShape
    def initialize(refusal:)
      @refusal = refusal
    end

    def check(node)
      form = PoolFileForms.of(node)
      @refusal.node_arguments(node, form, node.arguments.size) unless form.takes?(node)
      refuse_properties(node, form)
      refuse_children(node, form)
    end

    private def refuse_properties(node, form)
      stray = form.stray_property(node)
      @refusal.unknown_property(node, stray, form) if stray
      missing = form.missing_property(node)
      @refusal.missing_property(node, missing) if missing
    end

    private def refuse_children(node, form)
      node.each_child { |child, first| refuse_child(node, child, first) }
      missing = form.missing_child(node)
      @refusal.missing_child(node, missing) if missing
    end

    private def refuse_child(parent, child, first)
      form = PoolFileForms.of(parent)
      @refusal.unknown_child(parent, child, form) if form.lacks_child?(child)
      @refusal.repeated_child(child, first) if first && !PoolFileForms.of(child).repeatable
      check(child)
    end
  end
end
