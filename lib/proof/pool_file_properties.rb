# frozen_string_literal: true

module Proof
  class PoolFileProperties
    DAYS = -> (name) { -> (node) { Duration.read(node.properties[name], units: %i[d], name: "retention #{name}") } }
    SIZE = -> (name) { -> (node) { Size.read(node.properties[name], name: "limits #{name}") } }
    # @type var tables: Hash[Symbol, Hash[Symbol, KdlMembers::entry]]
    tables = {
      server: { port: [:port, -> (node) { Port.new(number: node.properties["port"]) }] },
      retention: %w[runs output artifacts].to_h { |name| [name.to_sym, [name.to_sym, DAYS.call(name)]] },
      limits: %w[output artifacts].to_h { |name| [name.to_sym, [name.to_sym, SIZE.call(name)]] },
    }
    TABLES = tables.freeze
    PARTS = {
      server: -> (values) { values },
      retention: -> (values) { { retention: Retention.new(**values) } },
      limits: -> (values) { { limits: Limits.new(**values) } },
    }.freeze
    private_constant(:DAYS, :SIZE, :TABLES, :PARTS)

    def initialize(refusal:)
      @members = TABLES.transform_values { |table| KdlMembers.new(table, refusal:) }
    end

    def read(by_name)
      parts = PARTS.filter_map { |name, part| part_of(name, part, by_name[name]&.first) }
      parts.reduce({}, :merge)
    end

    private def part_of(name, part, node)
      part.call(@members[name].of_properties(node)) if node
    end
  end
end
