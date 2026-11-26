# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class PoolFileForm < Data.define(:name, :usage, :arguments, :properties, :required, :children, :needs, :repeatable)
    # steep:ignore:end
    NONE = Array.new(0).freeze
    DEFAULTS = {
      arguments: 0..0, properties: NONE, required: NONE, children: NONE, needs: NONE, repeatable: false
    }.freeze
    TAKES = { 0..0 => "no arguments", 1..1 => "one argument", 1.. => "one or more arguments" }.freeze
    private_constant(:NONE, :DEFAULTS, :TAKES)

    def initialize(name:, usage:, **given)
      # The members after the first two arrive as one hash, since eight keywords make a parameter list longer than
      # RuboCop accepts, and most forms leave most of them at their default.
      super(name:, usage:, **DEFAULTS.merge(given))
    end

    def takes?(node)
      arguments.cover?(node.arguments.size)
    end

    def stray_property(node)
      node.properties.each_key.find { |property| !properties.include?(property.to_sym) }
    end

    def missing_property(node)
      missing = required.find { |property| !node.properties.key?(property.to_s) }
      missing&.to_s
    end

    def missing_child(node)
      present = node.children.map(&:name)
      missing = needs.find { |child| !present.include?(child.to_s) }
      missing&.to_s
    end

    def facts(count)
      { takes: TAKES[arguments], usage:, count: }
    end

    def lacks_child?(child)
      !children.include?(child.name.to_sym)
    end
  end
end
