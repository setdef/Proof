# frozen_string_literal: true

require_relative("project_file_refusal")

module Proof
  class ProjectFileSettingsRefusal < ProjectFileRefusal
    MESSAGES = {
      unknown_property: "a %p node has no property %p. Its properties are cpus, memory, and timeout",
      property_that_is_a_child: "%p is a child node, not a property. " \
        "Put it in the node's block, with every value as an argument",
      unknown_child: "a %p node has no child %p. Its children are os, label, artifact, and cache",
    }.freeze
    private_constant(:MESSAGES)

    def unknown_property(node, name)
      say(node, :unknown_property, node.name, name)
    end

    def property_that_is_a_child(node, name)
      say(node, :property_that_is_a_child, name)
    end

    def unknown_child(parent, child)
      say(child, :unknown_child, parent.name, child.name)
    end

    private def messages
      MESSAGES
    end
  end
end
