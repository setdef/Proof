# frozen_string_literal: true

require_relative("fact")
require_relative("final")

module Proof
  class Run
    # steep:ignore:start
    class Failed < Data.define(:at)
      # steep:ignore:end
      include Fact
      include Final
    end
  end
end
