# frozen_string_literal: true

module Proof
  class ProjectFileProperties
    KEYS = { cpus: :cpus, memory: :megabytes, timeout: :time_limit }.freeze
    BUILDERS = {
      cpus: -> (cpus) { Resources.request(cpus:, memory: "0MB").cpus },
      memory: -> (memory) { Resources.request(cpus: 1, memory:).megabytes },
      timeout: -> (text) { TimeLimit.read(text) },
    }.freeze
    private_constant(:KEYS, :BUILDERS)

    def initialize(refusal:)
      @refusal = refusal
    end

    def read(node)
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
      [KEYS[key], @refusal.checking(node) { BUILDERS[key].call(value) }]
    end
  end
end
