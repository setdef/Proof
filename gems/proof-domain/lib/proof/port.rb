# frozen_string_literal: true

module Proof
  class Port < Data.define(:number)
    MESSAGE = "the server's port is a whole number from 1 to 65535, not %p"
    LARGEST = 65_535
    private_constant(:MESSAGE, :LARGEST)

    def initialize(number:)
      raise(InvalidPortError, format(MESSAGE, number)) unless
        number.is_a?(Integer) && number.between?(1, LARGEST)

      super
    end

    # @dynamic number
  end
end
