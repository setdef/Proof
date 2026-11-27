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
      KdlFormCheck.new(forms: PoolFileForms, refusal: @refusal).check(nodes)
      PoolFile.new(**parts_of(nodes.group_by { |node| node.name.to_sym }))
    end

    private def parts_of(by_name)
      refuse_shared_names(by_name)
      parts = @readers.map { |reader| reader.read(by_name) }
      parts.reduce({}, :merge)
    end

    private def refuse_shared_names(by_name)
      # A second host is refused before a runner on two hosts, and both before a second repository, in the order the
      # domain's PoolFile refuses them.
      hosts = by_name[:host].to_a
      PoolFileRepeatedEntries.new(hosts, refusal: @refusal).check
      PoolFileSharedRunners.new(hosts, refusal: @refusal).check
      PoolFileRepeatedEntries.new(by_name[:repository].to_a, refusal: @refusal).check
    end
  end
end
