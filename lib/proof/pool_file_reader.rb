# frozen_string_literal: true

module Proof
  class PoolFileReader
    PATH = "~/.config/proof/pool.kdl"
    NODES = {
      server: -> (values) { values },
      retention: -> (values) { { retention: Retention.new(**values) } },
      limits: -> (values) { { limits: Limits.new(**values) } },
    }.freeze
    public_constant(:PATH)
    private_constant(:NODES)

    def self.read(text, path: PATH)
      new(path:).read(text)
    end

    def initialize(path:)
      @path = path
      @refusal = PoolFileRefusal.new(path:)
      @shape = PoolFileShape.new(refusal: @refusal)
      @properties = PoolFileProperties.new(refusal: @refusal)
    end

    def read(text)
      by_name = KdlParser.parse(text, path: @path, error: PoolFileError).group_by { |node| node.name.to_sym }
      by_name.each { |name, nodes| @refusal.unknown_node(nodes.first) unless NODES.key?(name) }
      PoolFile.new(**parts_of(by_name.values))
    end

    private def parts_of(groups)
      nodes = groups.filter_map { |same| single(same) }
      parts = nodes.map { |node| part_of(node) }
      parts.reduce({}, :merge)
    end

    private def single(nodes)
      first, second = nodes
      @refusal.repeated_node(second, first) if first && second
      first
    end

    private def part_of(node)
      @shape.check(node)
      NODES[node.name.to_sym].call(@properties.read(node))
    end
  end
end
