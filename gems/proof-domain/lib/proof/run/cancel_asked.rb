# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    class CancelAsked < Data.define(:at)
      include Fact
    end
  end
end
