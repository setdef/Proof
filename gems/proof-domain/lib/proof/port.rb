# frozen_string_literal: true

require_relative("member_check")

module Proof
  # steep:ignore:start
  class Port < Data.define(:number)
    # steep:ignore:end
    MESSAGE = "the server's port is a whole number from 1 to 65535, not %p"
    LARGEST = 65_535
    private_constant(:MESSAGE, :LARGEST)

    def initialize(number:)
      raise(InvalidPortError, format(MESSAGE, number)) unless MemberCheck.whole?(number, 1) && number <= LARGEST

      super
    end
  end
end
