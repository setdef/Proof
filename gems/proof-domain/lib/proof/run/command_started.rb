# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    class CommandStarted < Data.define(:at)
      include Fact
    end
  end
end
