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
      repeated_child: "%<name>p is given twice, and the first is on line %<line>d. " \
        "Give every value as arguments to one %<name>p node",
      missing_property: "a %<name>p node needs the property %<property>p",
      missing_child: "a %<name>p node needs a %<child>p child",
      blank_name: "%<what>s is not empty and not only spaces, not %<value>p",
    }.freeze
    KNOWN = lambda do |names, what|
      # Two names take "and" with no comma, and three or more take a serial comma.
      case names.size
      when 0 then "It has no #{what}"
      when 1, 2 then "Its #{what} are #{names.join(' and ')}"
      else "Its #{what} are #{names.first(names.size - 1).join(', ')}, and #{names.last}"
      end
    end
    private_constant(:MESSAGES, :KNOWN)

    def initialize(path:)
      super(path:, error: PoolFileError, messages: MESSAGES)
    end

    def unknown_node(node)
      say(node, :unknown_node, node.name)
    end

    def repeated_node(node, first)
      say_of(node, :repeated_node, line: first.line)
    end

    def node_arguments(node, form, count)
      say_of(node, :node_arguments, **form.facts(count))
    end

    def unknown_property(node, property, form)
      return say(node, :property_that_is_a_child, property:) if form.children.include?(property.to_sym)

      say_of(node, :unknown_property, property:, known: KNOWN.call(form.properties, "properties"))
    end

    def unknown_child(parent, child, form)
      say(child, :unknown_child, name: parent.name, child: child.name, known: KNOWN.call(form.children, "children"))
    end

    def repeated_child(child, first)
      say_of(child, :repeated_child, line: first.line)
    end

    def missing_property(node, property)
      say_of(node, :missing_property, property:)
    end

    def missing_child(node, child)
      say_of(node, :missing_child, child:)
    end

    def blank_name(node, what, value)
      say(node, :blank_name, what:, value:)
    end

    private def say_of(node, key, **values)
      # Most messages start with the name of the node they are about.
      say(node, key, name: node.name, **values)
    end
  end
end
