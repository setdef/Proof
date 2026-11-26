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
      symbols = Array.new(length) { ALPHABET[source.rand(ALPHABET.length)] }
      symbols.join
    end
  end
end
