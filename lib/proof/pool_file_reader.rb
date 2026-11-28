# frozen_string_literal: true

module Proof
  class PoolFileReader
    PATH = "~/.config/proof/pool.kdl"
    public_constant(:PATH)

    def self.read(text, path: PATH)
      new(path:).read(text)
    end

    attr_reader(:file)

    def initialize(path:)
      @file = KdlFile.new(path:, error: PoolFileError, forms: PoolFileForms, messages: PoolFileRefusal::MESSAGES)
      @refusal = @file.refusal(PoolFileRefusal)
      @readers = [PoolFileProperties, PoolFileHosts, PoolFileRepositories].map { |kind| kind.new(refusal: @refusal) }
    end

    def read(text)
      PoolFile.new(**parts_of(@file.nodes_by_name(text, refusal: @refusal)))
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

    # @dynamic file
  end
end
