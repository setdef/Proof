# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    class ProcessesEnded < Data.define(:at)
      include Fact
    end
  end
end
