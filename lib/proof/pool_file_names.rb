# frozen_string_literal: true

module Proof
  class PoolFileNames
    # @type var kinds: Hash[kind, [String, String]]
    kinds = {
      runner: ["a runner's name", "nuc-linux"],
      "credentials-file": ["a credentials file's path", "~/.config/proof/credentials/lota"],
      branch: ["a branch's name", "trunk"],
      task: ["a task's name", "test"],
    }
    KINDS = kinds.freeze
    private_constant(:KINDS)

    def initialize(refusal:)
      @refusal = refusal
    end

    def read(node, kind)
      node.pairs_named(kind.to_s).map { |value, child| name_at(child, value, kind) }
    end

    private def name_at(child, value, kind)
      # Only text is read as a name here: the domain refuses a value that isn't text, with its own message, at the line
      # of the entry. The signature limits a kind to the four that KINDS has, so the lookup finds its words.
      return value unless value.is_a?(String)

      what, example = KINDS[kind] #: [String, String]
      @refusal.checking(child) { Name.read(value, what:, example:) }
    end
  end
end
