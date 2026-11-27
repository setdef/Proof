# frozen_string_literal: true

require "openssl"

module Proof
  # steep:ignore:start
  class OneTimeCode < Data.define(:characters)
    # steep:ignore:end
    LENGTH = 8
    public_constant(:LENGTH)

    REFUSAL = "a one-time code is 8 letters and digits other than U, such as Q8MR-2T4W"
    private_constant(:REFUSAL)

    def self.generate(random:)
      new(characters: Crockford.random(LENGTH, random))
    end

    def self.parse(text)
      # One hyphen, between the two groups of four, is the only separator read. Removing the first hyphen leaves
      # any other in the text, which the reading then refuses.
      grouped = text.is_a?(String) && text[4] == "-"
      new(characters: grouped ? text.sub("-", "") : text)
    end

    def initialize(characters:)
      reading = characters.is_a?(String) ? Crockford.read(characters) : nil
      raise(InvalidOneTimeCodeError, REFUSAL) unless reading&.length == LENGTH

      super(characters: reading.freeze)
    end

    def ==(other)
      # Data#== compares with String#==, which stops at the first byte that differs, so its time tells how much of a
      # guess was right. Both codes have 8 characters, which OpenSSL's fixed-length comparison needs.
      other.is_a?(self.class) && OpenSSL.fixed_length_secure_compare(characters, other.characters)
    end
    alias eql? ==

    def to_s
      "#{characters[0, 4]}-#{characters[4, 4]}".upcase
    end

    def inspect
      "#<#{self.class}>"
    end

    def pretty_print(printer)
      # pp defines Data#pretty_print to print every member, and IRB and the debugger print with it, not with inspect.
      printer.text(inspect)
    end
  end
end
