# frozen_string_literal: true

module Proof
  class Run
    # steep:ignore:start
    module Fact
      # steep:ignore:end
      def self.count(value, minimum, message)
        return value if value.is_a?(Integer) && value >= minimum

        raise(InvalidFactError, format(message, value))
      end

      def self.name_of(value, message)
        # named? has found a String, which Steep can't know.
        # steep:ignore:start
        frozen = -value if MemberCheck.named?(value)
        # steep:ignore:end
        return frozen if frozen

        raise(InvalidFactError, format(message, value))
      end

      def self.listed(facts)
        return facts if facts.is_a?(Array) && !facts.empty? && facts.all?(Fact)

        raise(InvalidRunError, format("a run's facts are a list of one or more facts, not %p", facts))
      end

      def initialize(at:, **members)
        raise(InvalidFactError, format("a fact's time is a Time, not %p", at)) unless at.is_a?(Time)

        # A Time can change its zone in place, so the fact keeps a frozen copy in UTC.
        super(at: at.getutc.freeze, **members)
      end
    end
  end
end
