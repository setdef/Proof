# frozen_string_literal: true

require_relative("file_refusal")

module Proof
  class KdlRefusal < FileRefusal
    KNOWN = lambda do |names, kind|
      # One name takes "only" and the singular, two take "and" with no comma, and three or more take a serial comma.
      singular, plural = kind
      return "It has no #{plural}" if names.empty?
      return "Its only #{singular} is #{names.first}" if names.one?

      "Its #{plural} are #{names.first(names.size - 1).join(', ')}#{',' if names.size > 2} and #{names.last}"
    end
    PROPERTIES = %w[property properties].freeze
    CHILDREN = %w[child children].freeze
    private_constant(:KNOWN, :PROPERTIES, :CHILDREN)

    def initialize(path:, error:, messages:, forms:)
      super(path:, error:, messages:)
      @forms = forms
    end

    def unknown_node(node)
      say_of(node, :unknown_node)
    end

    def repeated_node(node, first)
      say_of(node, :repeated_node, line: first.line)
    end

    def node_arguments(node, count)
      say_of(node, :node_arguments, **form_of(node).facts(count))
    end

    def stray_property(node, property)
      form = form_of(node)
      return say(node, :property_that_is_a_child, property:) if form.children.include?(property.to_sym)

      say_of(node, :unknown_property, property:, known: KNOWN.call(form.properties, PROPERTIES))
    end

    def stray_child(parent, child)
      form = form_of(parent)
      name = child.name
      return unknown_child(parent, child) unless form.properties.include?(name.to_sym)

      say(child, :child_that_is_a_property, child: name, usage: form.usage)
    end

    def repeated_child(child, first)
      say_of(child, :repeated_child, line: first.line)
    end

    def missing(node, kind, missing)
      say_of(node, :missing, kind:, missing:, usage: form_of(node).usage)
    end

    private def unknown_child(parent, child)
      known = KNOWN.call(form_of(parent).children, CHILDREN)
      say(child, :unknown_child, name: parent.name, child: child.name, known:)
    end

    private def form_of(node)
      @forms.of(node)
    end

    private def say_of(node, key, **values)
      # Most messages start with the name of the node they are about.
      say(node, key, name: node.name, **values)
    end
  end
end
