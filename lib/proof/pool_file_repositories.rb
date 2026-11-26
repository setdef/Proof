# frozen_string_literal: true

module Proof
  class PoolFileRepositories
    BLANKS = %i[credentials-file branch task].freeze
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
      BLANKS.each { |kind| @names.refuse_children(node, kind) }
    end
  end
end
