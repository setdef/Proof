# frozen_string_literal: true

module Proof
  module Name
    TEXT = "text with at least one character that isn't white space"
    BLANK = /\A[[:space:]]*\z/
    private_constant(:BLANK)
    public_constant(:TEXT)

    def self.valid?(value)
      # Text with a byte that isn't valid, or in an encoding such as UTF-16, can't be searched for white space.
      value.is_a?(String) && value.valid_encoding? && value.encoding.ascii_compatible? && !BLANK.match?(value)
    end

    def self.list?(value)
      value.is_a?(Array) && !value.empty? && value.all? { |name| valid?(name) } && value.uniq.size == value.size
    end

    def self.distinct_list?(value)
      # Two names that differ only in case are one name, as same? finds. list? has found an Array of names, which Steep
      # can't know. Steep also reads each member of a pair from combination as possibly nil, and a pair has two names.
      return false unless list?(value)

      names = value #: Array[String]
      pairs = names.combination(2) #: Enumerator[[String, String], Array[String]]
      pairs.none? { |one, other| same?(one, other) }
    end

    def self.message(what, example)
      "#{what} is #{TEXT}, such as #{example}, not %p"
    end

    def self.same?(one, other)
      # String#casecmp? folds Unicode case, where String#casecmp folds only ASCII letters.
      one.casecmp?(other)
    end

    def self.read(value, what:, example:)
      raise(InvalidNameError, format(message(what, example), value)) unless valid?(value)

      # valid? has found a String, which Steep can't know.
      text = value #: String
      -text
    end
  end
end
