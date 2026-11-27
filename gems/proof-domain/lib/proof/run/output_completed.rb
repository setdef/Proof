# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    # steep:ignore:start
    class OutputCompleted < Data.define(:at, :bytes)
      # steep:ignore:end
      include Fact

      def initialize(at:, bytes:)
        super(at:, bytes: Fact.count(bytes, 0, "a run's output is a whole number of bytes from 0, not %p"))
      end
    end
  end
end
