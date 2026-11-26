# frozen_string_literal: true

module Proof
  class KdlFormCheck
    def initialize(forms:, refusal:)
      @forms = forms
      @refusal = refusal
    end

    def check(nodes)
      KdlNode.each_after_first(nodes) { |node, first| check_top(node, first) }
    end

    private def check_top(node, first)
      @refusal.unknown_node(node) unless @forms.top?(node)
      @refusal.repeated_node(node, first) if first && @forms.once?(node)
      check_node(node)
    end

    private def check_child(parent, child, first)
      @refusal.stray_child(parent, child) if @forms.of(parent).lacks_child?(child)
      @refusal.repeated_child(child, first) if first && @forms.once?(child)
      check_node(child)
    end

    private def check_node(node)
      form = @forms.of(node)
      @refusal.node_arguments(node, node.arguments.size) unless form.takes?(node)
      check_properties(node, form)
      check_children(node, form)
    end

    private def check_properties(node, form)
      stray = form.stray_property(node)
      @refusal.stray_property(node, stray) if stray
      refuse_missing(node, "property", form.missing_property(node))
    end

    private def check_children(node, form)
      node.each_child { |child, first| check_child(node, child, first) }
      refuse_missing(node, "child", form.missing_child(node))
    end

    private def refuse_missing(node, kind, missing)
      @refusal.missing(node, kind, missing) if missing
    end
  end
end
