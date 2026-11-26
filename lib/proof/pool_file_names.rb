# frozen_string_literal: true

module Proof
  class PoolFileNames
    BLANK = -> (value) { value.is_a?(String) && value.match?(/\A[[:space:]]*\z/) }
    KINDS = {
      host: ["a host's name", "nuc"],
      runner: ["a runner's name", "nuc-linux"],
      repository: ["a repository's name", "lota"],
      url: ["a repository's url", "https://github.com/setdef/Lota.git"],
      "credentials-file": ["a credentials file's path", "~/.config/proof/credentials/lota"],
      branch: ["a branch's name", "trunk"],
      task: ["a task's name", "test"],
    }.freeze
    private_constant(:BLANK, :KINDS)

    def initialize(refusal:)
      @refusal = refusal
    end

    def refuse(node, kind, value)
      @refusal.blank_name(node, KINDS[kind], value) if BLANK.call(value)
    end

    def refuse_children(node, kind)
      node.pairs_named(kind.to_s).each { |value, child| refuse(child, kind, value) }
    end
  end
end
