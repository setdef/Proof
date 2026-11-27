# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    # steep:ignore:start
    class ProcessesEnded < Data.define(:at)
      # steep:ignore:end
      include Fact
    end
  end
end
