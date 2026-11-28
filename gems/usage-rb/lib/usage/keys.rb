# frozen_string_literal: true

require "json"

module Usage
  class Keys < Data.define(:read, :defaults)
    def initialize(read:, defaults: {})
      super
    end

    def check(object, place)
      # A key the gem doesn't know, or a value it can't act on, would change what the spec means if it were skipped,
      # so each is refused by name, and the gem can learn it later without changing what it accepts now.
      object.each do |key, value|
        refusal = refusal(key, value)
        place.unsupported(refusal) if refusal
      end
    end

    private def refusal(key, value)
      return if read.include?(key)
      return "has #{key}" unless defaults.key?(key)

      "sets #{key} to #{JSON.generate(value)}" unless defaults[key] == value
    end

    # @dynamic read, defaults
  end
end
