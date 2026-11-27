# frozen_string_literal: true

module Proof
  class PoolFileNames
    KINDS = {
      runner: ["a runner's name", "nuc-linux"],
      "credentials-file": ["a credentials file's path", "~/.config/proof/credentials/lota"],
      branch: ["a branch's name", "trunk"],
      task: ["a task's name", "test"],
    }.freeze
    private_constant(:KINDS)

    def self.same?(one, other)
      # Text compares by the domain's rule, Name.same?. A name that isn't text, which the domain refuses later, compares
      # as KDL read it.
      (one.is_a?(String) && other.is_a?(String)) ? Name.same?(one, other) : one == other
    end

    def self.among?(names, name)
      names.any? { |other| same?(other, name) }
    end

    def initialize(refusal:)
      @refusal = refusal
    end

    def read(node, kind)
      node.pairs_named(kind.to_s).map { |value, child| name_at(child, value, kind) }
    end

    private def name_at(child, value, kind)
      # Only text is read as a name here: the domain refuses a value that isn't text, with its own message, at the line
      # of the entry. Every kind has its words, and Steep is told that a lookup in a Hash finds them.
      return value unless value.is_a?(String)

      what, example = KINDS[kind]
      # steep:ignore:start
      @refusal.checking(child) { Name.read(value, what:, example:) }
      # steep:ignore:end
    end
  end
end
