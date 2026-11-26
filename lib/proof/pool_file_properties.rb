# frozen_string_literal: true

module Proof
  class PoolFileProperties
    BUILDERS = {
      server: { port: -> (value) { Port.new(number: value) } },
      retention: {
        runs: -> (value) { Duration.read(value, units: %i[d], name: "retention runs") },
        output: -> (value) { Duration.read(value, units: %i[d], name: "retention output") },
        artifacts: -> (value) { Duration.read(value, units: %i[d], name: "retention artifacts") },
      },
      limits: {
        output: -> (value) { Size.read(value, name: "limits output") },
        artifacts: -> (value) { Size.read(value, name: "limits artifacts") },
      },
    }.freeze
    PARTS = {
      server: -> (values) { values },
      retention: -> (values) { { retention: Retention.new(**values) } },
      limits: -> (values) { { limits: Limits.new(**values) } },
    }.freeze
    private_constant(:BUILDERS, :PARTS)

    def initialize(refusal:)
      @refusal = refusal
    end

    def read(by_name)
      nodes = PARTS.keys.filter_map { |name| by_name[name]&.first }
      parts = nodes.map { |node| PARTS[node.name.to_sym].call(values_of(node)) }
      parts.reduce({}, :merge)
    end

    private def values_of(node)
      node.properties.to_h { |name, value| pair(node, name.to_sym, value) }
    end

    private def pair(node, key, value)
      [key, @refusal.checking(node) { BUILDERS[node.name.to_sym][key].call(value) }]
    end
  end
end
