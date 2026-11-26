# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class RunId < Data.define(:minute, :characters)
    # steep:ignore:end
    def self.generate(clock:, random:)
      new(minute: clock.now, characters: Crockford.random(5, random))
    end

    def self.parse(text)
      new(**RunIdText.read(text))
    end

    def initialize(minute:, characters:)
      super(minute: utc_minute(minute), characters: five_characters(characters))
    end

    def identified_by?(text)
      return characters == Crockford.read(text) unless text.include?("-")

      self == self.class.parse(text)
    rescue InvalidRunIdError
      false
    end

    def to_s
      "#{minute.strftime('%Y%m%d-%H%M')}-#{characters}"
    end

    private def utc_minute(moment)
      unless moment.is_a?(Time) && moment.getutc.year.between?(0, 9999)
        raise(InvalidRunIdError, format("the minute of a run ID is a Time in the years 0 to 9999, not %p", moment))
      end

      Time.at(Integer(moment).div(60) * 60, in: "UTC").freeze
    end

    private def five_characters(given)
      reading = given.is_a?(String) ? Crockford.read(given) : nil
      return reading if reading && reading.length == 5

      raise(InvalidRunIdError, format("a run ID ends in five Crockford Base32 characters, not %p", given))
    end
  end
end
