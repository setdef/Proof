# frozen_string_literal: true

require "json"

module Usage
  module Keys
    def self.check(object, place, keys)
      # A key the reader doesn't know, or a value it can't act on, would change what the spec means if it were
      # skipped, so each is refused by name, and the gem can learn it later without changing what it accepts now.
      object.each do |key, value|
        refusal = refusal(key.to_s, JSON.generate(value), keys)
        place.unsupported(refusal) if refusal
      end
    end

    def self.refusal(key, value, keys)
      return if keys.include?(key) || keys.include?("#{key}=#{value}")

      (keys.any? { |each| each.start_with?("#{key}=") }) ? "sets #{key} to #{value}" : "has #{key}"
    end
    private_class_method(:refusal)
  end
end
