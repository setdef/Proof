# frozen_string_literal: true

require_relative("fact")
require_relative("final")

module Proof
  class Run
    class Canceled < Data.define(:at)
      include Fact
      include Final
    end
  end
end
