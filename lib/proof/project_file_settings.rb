# frozen_string_literal: true

module Proof
  class ProjectFileSettings
    MEMBERS = { cpus: :cpus, memory: :megabytes, timeout: :time_limit }.freeze
    BUILDERS = {
      cpus: -> (cpus) { Resources.request(cpus:, memory: "0MB").cpus },
      memory: -> (memory) { Resources.request(cpus: 1, memory:).megabytes },
      timeout: -> (text) { TimeLimit.read(text) },
    }.freeze
    private_constant(:MEMBERS, :BUILDERS)

    def initialize(refusal:)
      @refusal = refusal
      @children = ProjectFileChildren.new(refusal:)
    end

    def read(node)
      single = properties_of(node)
      listed = @children.read(node)
      # Every value is built and checked above, so TaskSettings has nothing left to refuse.
      TaskSettings.new(**single, **listed)
    end

    private def properties_of(node)
      refuse_unknown_in(node)
      node.properties.to_h { |name, value| pair(node, name.to_sym, value) }
    end

    private def refuse_unknown_in(node)
      node.properties.each_key { |name| refuse(node, name) unless BUILDERS.key?(name.to_sym) }
    end

    private def refuse(node, name)
      if ProjectFileChildren::NAMES.include?(name)
        @refusal.property_that_is_a_child(node, name)
      else
        @refusal.unknown_property(node, name)
      end
    end

    private def pair(node, key, value)
      [MEMBERS[key], @refusal.checking(node) { BUILDERS[key].call(value) }]
    end
  end
end
