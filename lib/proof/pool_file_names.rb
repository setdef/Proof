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

    def initialize(refusal:)
      @refusal = refusal
    end

    def refuse_children(node, kind)
      what, example = KINDS[kind]
      node.pairs_named(kind.to_s).each do |value, child|
        # Only text is checked here: the domain refuses a value that isn't text, with its own message. Every kind
        # has its words, and Steep is told that a lookup in a Hash finds them.
        # steep:ignore:start
        @refusal.checking(child) { Name.read(value, what:, example:) } if value.is_a?(String)
        # steep:ignore:end
      end
    end
  end
end
