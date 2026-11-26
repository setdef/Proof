# frozen_string_literal: true

require_relative("duration_text")
require_relative("member_check")

module Proof
  # steep:ignore:start
  class Duration < Data.define(:seconds)
    # steep:ignore:end
    EXAMPLES = { d: "30d", h: "2h", m: "30m", s: "90s" }.freeze
    MESSAGE = "%<name>s is a duration: a whole number from 1 and then %<units>s in lowercase, with no space, " \
      "such as %<examples>s, not %<text>p"
    private_constant(:EXAMPLES, :MESSAGE)

    def self.read(text, units:, name:)
      seconds = DurationText.seconds(text, units)
      raise(InvalidDurationError, refusal(text, units, name)) unless seconds

      new(seconds:)
    end

    def initialize(seconds:)
      raise(InvalidDurationError, format("a duration is a whole number of seconds from 1, not %p", seconds)) unless
        MemberCheck.whole?(seconds, 1)

      super
    end

    def self.refusal(text, units, name)
      examples = units.map { |unit| EXAMPLES[unit].inspect }
      format(MESSAGE, name:, units: listed(units), examples: listed(examples), text:)
    end
    private_class_method(:refusal)

    def self.listed(items)
      # Two items take "or" with no comma, and three or more take a serial comma.
      return items.join(" or ") if items.size < 3

      "#{items[0...-1].join(', ')}, or #{items.last}"
    end
    private_class_method(:listed)
  end
end
