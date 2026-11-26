# frozen_string_literal: true

require_relative("duration_text")

module Proof
  # steep:ignore:start
  class TimeLimit < Data.define(:seconds)
    # steep:ignore:end
    include Comparable

    MESSAGE = "timeout is a duration: a whole number from 1 and then s, m, or h in lowercase, " \
      "with no space, such as \"90s\", \"30m\", or \"2h\", not %p"
    private_constant(:MESSAGE)

    def self.read(text)
      seconds = DurationText.seconds(text)
      raise(InvalidTimeLimitError, format(MESSAGE, text)) unless seconds

      new(seconds:)
    end

    def initialize(seconds:)
      raise(InvalidTimeLimitError, format("a time limit is a whole number of seconds from 1, not %p", seconds)) unless
        seconds.is_a?(Integer) && seconds >= 1

      super
    end

    def <=>(other)
      case other
      in TimeLimit(seconds: theirs) then seconds <=> theirs
      else nil
      end
    end
  end
end
