# frozen_string_literal: true

require_relative("project_file_refusal")

module Proof
  class ProjectFileSettingsRefusal < ProjectFileRefusal
    MESSAGES = {
      unknown_property: "a %p node has no property %p. Its properties are cpus, memory, and timeout",
      property_that_is_a_child: "%p is a child node, not a property. " \
        "Put it in the node's block, with every value as an argument",
      unknown_child: "a %p node has no child %p. Its children are os, label, artifact, and cache",
      repeated_child: "%1$p is given twice, and the first is on line %2$d. " \
        "Give every value as arguments to one %1$p node",
      child_without_arguments: "%p takes one or more arguments, and this one has none",
      child_with_more: "%p takes arguments only, with no properties and no children",
    }.freeze
    private_constant(:MESSAGES)

    def initialize(path:)
      super(path:, messages: MESSAGES)
    end

    def unknown_property(node, name)
      say(node, :unknown_property, node.name, name)
    end

    def property_that_is_a_child(node, name)
      say(node, :property_that_is_a_child, name)
    end

    def unknown_child(parent, child)
      say(child, :unknown_child, parent.name, child.name)
    end

    def repeated_child(child, first)
      say(child, :repeated_child, child.name, first.line)
    end

    def child_without_arguments(child)
      say(child, :child_without_arguments, child.name)
    end

    def child_with_more(child)
      say(child, :child_with_more, child.name)
    end
  end
end
