# frozen_string_literal: true

require_relative("fact")
require_relative("final")

module Proof
  class Run
    class Failed < Data.define(:at)
      include Fact
      include Final

      # @dynamic at
    end
  end
end
