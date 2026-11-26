# frozen_string_literal: true

require_relative("file_refusal")

module Proof
  class PoolFileRefusal < FileRefusal
    MESSAGES = {
      unknown_node: "there is no node %p in a pool file. A pool file has \"server\", \"retention\", " \
        "and \"limits\" nodes",
      repeated_node: "a pool file has at most one %<name>p node, and the first is on line %<line>d. " \
        "Merge them into one",
      node_arguments: "a %<name>p node has no arguments, as in %<usage>s, and this one has %<count>d",
      unknown_property: "a %<name>p node has no property %<property>p. Its properties are %<known>s",
      no_children: "a %<name>p node has no children, and this one has %<child>p",
    }.freeze
    private_constant(:MESSAGES)

    def initialize(path:)
      super(path:, error: PoolFileError, messages: MESSAGES)
    end

    def unknown_node(node)
      say(node, :unknown_node, node.name)
    end

    def repeated_node(node, first)
      say(node, :repeated_node, name: node.name, line: first.line)
    end

    def node_arguments(node, usage, count)
      say_of(node, :node_arguments, usage:, count:)
    end

    def unknown_property(node, property, known)
      say_of(node, :unknown_property, property:, known:)
    end

    def no_children(node, child)
      say(child, :no_children, name: node.name, child: child.name)
    end

    private def say_of(node, key, **values)
      # Most messages start with the name of the node they are about.
      say(node, key, name: node.name, **values)
    end
  end
end
