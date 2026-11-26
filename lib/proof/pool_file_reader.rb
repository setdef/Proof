# frozen_string_literal: true

module Proof
  class PoolFileReader
    PATH = "~/.config/proof/pool.kdl"
    public_constant(:PATH)

    def self.read(text, path: PATH)
      new(path:).read(text)
    end

    def initialize(path:)
      @path = path
      @refusal = PoolFileRefusal.new(path:)
      @readers = [PoolFileProperties, PoolFileHosts, PoolFileRepositories].map { |kind| kind.new(refusal: @refusal) }
    end

    def read(text)
      nodes = KdlParser.parse(text, path: @path, error: PoolFileError)
      PoolFileNodes.new(nodes:, refusal: @refusal).check
      PoolFile.new(**parts_of(nodes.group_by { |node| node.name.to_sym }))
    end

    private def parts_of(by_name)
      parts = @readers.map { |reader| reader.read(by_name) }
      parts.reduce({}, :merge)
    end
  end
end
