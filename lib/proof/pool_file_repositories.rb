# frozen_string_literal: true

module Proof
  class PoolFileRepositories
    BLANKS = {
      "credentials-file": "a credentials file's path", branch: "a branch's name", task: "a task's name"
    }.freeze
    private_constant(:BLANKS)

    def initialize(refusal:)
      @refusal = refusal
      @names = PoolFileNames.new(refusal:)
    end

    def read(by_name)
      { repositories: by_name[:repository].to_a.map { |node| entry(node) } }
    end

    private def entry(node)
      refuse_blanks(node)
      @refusal.checking(node) { PoolFileRepository.new(node:, refusal: @refusal).entry }
    end

    private def refuse_blanks(node)
      @names.refuse(node, "a repository's name", node.arguments.first)
      @names.refuse(node, "a repository's url", node.properties["url"])
      BLANKS.each { |name, what| @names.refuse_children(node, name.to_s, what) }
    end
  end
end
