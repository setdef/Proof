# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    class CommandEnded < Data.define(:at, :exit_status, :signal)
      include Fact

      LARGEST_EXIT_STATUS = 4_294_967_295
      private_constant(:LARGEST_EXIT_STATUS)

      ONE_WAY = "a command ends with an exit status or a signal, not exit_status=%<exit_status>p signal=%<signal>p"
      private_constant(:ONE_WAY)

      def initialize(at:, exit_status: nil, signal: nil)
        raise(InvalidFactError, format(ONE_WAY, exit_status:, signal:)) unless [exit_status, signal].one?

        super(
          at:, exit_status: exit_status && status(exit_status),
          signal: signal && Fact.count(signal, 1, "a signal is a whole number from 1, not %p"))
      end

      def exited_zero?
        exit_status&.zero? || false
      end

      private def status(given)
        # Windows gives a process an exit code of 32 bits, so the largest status is that, not 255.
        return given if given.is_a?(Integer) && given.between?(0, LARGEST_EXIT_STATUS)

        raise(
          InvalidFactError,
          format("an exit status is a whole number from 0 to #{LARGEST_EXIT_STATUS}, not %p", given)
        )
      end
    end
  end
end
