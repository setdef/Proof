# frozen_string_literal: true

module Proof
  class PoolFileRepositories
    def initialize(refusal:)
      @refusal = refusal
      @names = PoolFileNames.new(refusal:)
    end

    def read(by_name)
      { repositories: by_name[:repository].to_a.map { |node| entry(node) } }
    end

    private def entry(node)
      @refusal.checking(node) { PoolFileRepository.new(node:, refusal: @refusal, names: @names).entry }
    end
  end
end
