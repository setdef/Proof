# frozen_string_literal: true

require_relative("file_refusal")

module Proof
  class PoolFileRefusal < FileRefusal
    MESSAGES = {
      unknown_node: "there is no node %p in a pool file. A pool file has \"server\", \"retention\", \"limits\", " \
        "\"defaults\", \"host\", and \"repository\" nodes",
      repeated_node: "a pool file has at most one %<name>p node, and the first is on line %<line>d. " \
        "Merge them into one",
      node_arguments: "a %<name>p node takes %<takes>s, as in %<usage>s, and this one has %<count>d",
      unknown_property: "a %<name>p node has no property %<property>p. %<known>s",
      property_that_is_a_child: "%<property>p is a child node, not a property. " \
        "Put it in the node's block, with every value as an argument",
      unknown_child: "a %<name>p node has no child %<child>p. %<known>s",
      child_that_is_a_property: "%<child>p is a property, not a child node. " \
        "Write it on the line of the node, as in %<usage>s",
      repeated_child: "%<name>p is given twice, and the first is on line %<line>d. " \
        "Give every value as arguments to one %<name>p node",
      repeated_entry: "a second %<name>s is named %<entry>p, and the first is on line %<line>d. " \
        "Each %<name>s has one entry, so merge them into one",
      shared_runner: "the runner %<runner>p is also on the host %<entry>p, whose entry starts on line %<line>d. " \
        "A runner is one operating system on one host, so list it on one",
      missing: "a %<name>p node needs the %<kind>s %<missing>p, as in %<usage>s",
      blank_name: "%<what>s is text with at least one character that isn't white space, such as %<example>s, " \
        "not %<value>p",
    }.freeze
    KNOWN = lambda do |names, kind|
      # One name takes "only" and the singular, two take "and" with no comma, and three or more take a serial comma.
      singular, plural = kind
      return "It has no #{plural}" if names.empty?
      return "Its only #{singular} is #{names.first}" if names.one?

      "Its #{plural} are #{names.first(names.size - 1).join(', ')}#{',' if names.size > 2} and #{names.last}"
    end
    PROPERTIES = %w[property properties].freeze
    CHILDREN = %w[child children].freeze
    EARLIER = -> (node) { { entry: node.arguments.first, line: node.line } }
    private_constant(:MESSAGES, :KNOWN, :PROPERTIES, :CHILDREN, :EARLIER)

    def initialize(path:)
      super(path:, error: PoolFileError, messages: MESSAGES)
    end

    def unknown_node(node)
      say(node, :unknown_node, node.name)
    end

    def repeated_node(node, first)
      say_of(node, :repeated_node, line: first.line)
    end

    def node_arguments(node, count)
      say_of(node, :node_arguments, **PoolFileForms.of(node).facts(count))
    end

    def unknown_property(node, property)
      say_of(node, :unknown_property, property:, known: KNOWN.call(PoolFileForms.of(node).properties, PROPERTIES))
    end

    def property_that_is_a_child(node, property)
      say(node, :property_that_is_a_child, property:)
    end

    def unknown_child(parent, child)
      known = KNOWN.call(PoolFileForms.of(parent).children, CHILDREN)
      say(child, :unknown_child, name: parent.name, child: child.name, known:)
    end

    def child_that_is_a_property(parent, child)
      say(child, :child_that_is_a_property, child: child.name, usage: PoolFileForms.of(parent).usage)
    end

    def repeated_child(child, first)
      say_of(child, :repeated_child, line: first.line)
    end

    def repeated_entry(node, first)
      say_of(node, :repeated_entry, **EARLIER.call(first))
    end

    def shared_runner(child, runner, host)
      say(child, :shared_runner, runner:, **EARLIER.call(host))
    end

    def missing(node, kind, missing)
      say_of(node, :missing, kind:, missing:, usage: PoolFileForms.of(node).usage)
    end

    def blank_name(node, name, value)
      what, example = name
      say(node, :blank_name, what:, example:, value:)
    end

    private def say_of(node, key, **values)
      # Most messages start with the name of the node they are about.
      say(node, key, name: node.name, **values)
    end
  end
end
