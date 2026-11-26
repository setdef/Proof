# frozen_string_literal: true

module Proof
  module Crockford
    ALPHABET = "0123456789abcdefghjkmnpqrstvwxyz"
    public_constant(:ALPHABET)

    def self.read(text)
      return unless text.valid_encoding?

      reading = text.downcase(:ascii).tr("oil", "011")
      reading if /\A[0-9a-hjkmnp-tv-z]*\z/.match?(reading)
    end

    def self.random(length, source)
      symbols = Array.new(length) { ALPHABET[drawn(source)] }
      symbols.join
    end

    def self.drawn(source)
      limit = ALPHABET.length
      number = source.rand(limit)
      return number if number.is_a?(Integer) && number.between?(0, limit - 1)

      raise(InvalidRandomSourceError, format("a source of randomness answers a whole number below 32, not %p", number))
    end
    private_class_method(:drawn)
  end
end
