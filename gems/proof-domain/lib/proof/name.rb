# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class Name < Data.define(:text)
    # steep:ignore:end
    TEXT = "text with at least one character that isn't white space"
    BLANK = /\A[[:space:]]*\z/
    private_constant(:BLANK)
    public_constant(:TEXT)

    def self.valid?(value)
      # Text with a byte that isn't valid, or in an encoding such as UTF-16, can't be searched for white space.
      value.is_a?(String) && value.valid_encoding? && value.encoding.ascii_compatible? && !BLANK.match?(value)
    end

    def self.message(what, example)
      "#{what} is #{TEXT}, such as #{example}, not %p"
    end

    def self.read(value, what:, example:)
      raise(InvalidNameError, format(message(what, example), value)) unless valid?(value)

      new(text: value)
    end

    def initialize(text:)
      raise(InvalidNameError, format(Name.message("a name", "nuc"), text)) unless Name.valid?(text)

      super(text: -text)
    end
  end
end
