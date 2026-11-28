# frozen_string_literal: true

module Proof
  class Run
    module Fact
      def self.count(value, minimum, message)
        return value if value.is_a?(Integer) && value >= minimum

        raise(InvalidFactError, format(message, value))
      end

      def self.name_of(value, message)
        raise(InvalidFactError, format(message, value)) unless Name.valid?(value)

        # valid? has found a String, which Steep can't know.
        text = value #: String
        -text
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

      # @dynamic at
    end
  end
end
