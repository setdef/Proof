# frozen_string_literal: true

require_relative("test_helper")
require "minitest/mock"
require "securerandom"

# Checks the one-time code that a person types to sign in or to approve a runner: how it is made, read, written, and
# compared.
class OneTimeCodeTest < Minitest::Test
  # A source of randomness that returns the numbers it was given, in order, and remembers each limit it was asked for.
  class ScriptedRandom
    attr_reader :limits

    def initialize(*numbers)
      @numbers = numbers
      @limits = []
    end

    # The next number, after noting the limit.
    def rand(limit)
      @limits << limit
      @numbers.shift
    end
  end

  # The numbers of Q8MR2T4W in Crockford's Base32.
  Q8MR2T4W = [23, 8, 20, 24, 2, 26, 4, 28].freeze
  private_constant(:Q8MR2T4W)

  # Server design, "Tokens and codes": "One-time codes ... are 8 characters of Crockford's Base32", and glossary,
  # "random source": the random source gives the characters.
  def test_generate_draws_eight_characters_from_the_source
    random = ScriptedRandom.new(*Q8MR2T4W)

    assert_equal("q8mr2t4w", Proof::OneTimeCode.generate(random:).characters)
    assert_equal([32] * 8, random.limits)
  end

  # Ruby's SecureRandom is a random source, and two codes it draws differ.
  def test_generate_with_securerandom_makes_codes_that_differ
    codes = Array.new(2) { Proof::OneTimeCode.generate(random: SecureRandom) }

    refute_equal(codes.first, codes.last)
  end

  # Server design, "Tokens and codes": codes are "grouped 4-4".
  def test_to_s_writes_the_code_in_capitals_grouped_four_and_four
    assert_equal("Q8MR-2T4W", Proof::OneTimeCode.new(characters: "q8mr2t4w").to_s)
  end

  # Server design, "Tokens and codes": "Input is accepted in either case, with or without the hyphen".
  def test_parse_reads_either_case_with_or_without_the_hyphen
    readings = %w[Q8MR-2T4W q8mr-2t4w Q8MR2T4W q8mR2t4W].map { |text| Proof::OneTimeCode.parse(text).characters }

    assert_equal(["q8mr2t4w"] * 4, readings)
  end

  # Server design, "Tokens and codes": "with `O` read as `0` and `I` or `L` as `1`".
  def test_parse_reads_o_as_zero_and_i_or_l_as_one
    assert_equal("0011-1111", Proof::OneTimeCode.parse("oO1i-IlL1").to_s.downcase)
  end

  # Only the hyphen between the two groups is read, so a hyphen anywhere else, two hyphens, and a space are refused.
  def test_parse_refuses_a_hyphen_out_of_place_and_any_other_separator
    ["Q8M-R2T4W", "Q8MR--2T4W", "Q8MR-2T4W-", "-Q8MR2T4W", "Q8MR 2T4W", " Q8MR-2T4W"].each do |text|
      assert_raises(Proof::InvalidOneTimeCodeError, text) { Proof::OneTimeCode.parse(text) }
    end
  end

  # A code has 8 characters, and every one is in the alphabet, which has no U.
  def test_a_code_of_another_length_or_outside_the_alphabet_is_refused
    ["", "Q8MR-2T4", "Q8MR-2T4WX", "Q8MR-2T4U", "Q8MR-2T4K", "Q8MR-2T4\xFF"].each do |text|
      assert_raises(Proof::InvalidOneTimeCodeError, text.inspect) { Proof::OneTimeCode.parse(text) }
    end
  end

  # The constructor reads its characters as the alphabet writes them, and refuses anything but 8 of them.
  def test_the_constructor_reads_the_characters_and_refuses_anything_else
    assert_equal("q8mr2t40", Proof::OneTimeCode.new(characters: "Q8MR2T4O").characters)
    [nil, 12_345_678, "q8mr-2t4w"].each do |given|
      assert_raises(Proof::InvalidOneTimeCodeError, given.inspect) { Proof::OneTimeCode.new(characters: given) }
    end
  end

  # A refusal never repeats the text, which may be the code with one character mistyped.
  def test_a_refusal_never_repeats_what_was_typed
    error = assert_raises(Proof::InvalidOneTimeCodeError) { Proof::OneTimeCode.parse("Q8MR-2T4U") }

    assert_equal("a one-time code is 8 letters and digits other than U, such as Q8MR-2T4W", error.message)
  end

  # Two codes with the same characters are equal, whichever way each was typed.
  def test_codes_with_the_same_characters_are_equal
    code = Proof::OneTimeCode.parse("Q8MR-2T4W")

    assert_equal(code, Proof::OneTimeCode.parse("q8mr2t4w"))
    assert(code.eql?(Proof::OneTimeCode.parse("q8mr2t4w")))
  end

  # A wrong code never matches, and a code is never equal to its text.
  def test_a_code_differs_from_another_code_and_from_its_text
    code = Proof::OneTimeCode.parse("Q8MR-2T4W")

    refute_equal(code, Proof::OneTimeCode.parse("Q8MR-2T4X"))
    refute_equal(code, "q8mr2t4w")
    refute(code.eql?("q8mr2t4w"))
  end

  # Architecture, "Certificates": "Codes are ... compared in constant time." Equality goes through OpenSSL's
  # comparison of two strings of one length, which takes the same time wherever they differ.
  def test_equality_compares_in_constant_time
    compared = []
    comparison = lambda do |one, other|
      compared << [one, other]
      true
    end
    equal = OpenSSL.stub(:fixed_length_secure_compare, comparison) do
      Proof::OneTimeCode.parse("Q8MR-2T4W") == Proof::OneTimeCode.parse("ZZZZ-ZZZZ")
    end

    assert(equal)
    assert_equal([%w[q8mr2t4w zzzzzzzz]], compared)
  end

  # Equal codes have one hash, so a code can be a key.
  def test_equal_codes_have_one_hash
    assert_equal(Proof::OneTimeCode.parse("Q8MR-2T4W").hash, Proof::OneTimeCode.parse("q8mr2t4w").hash)
  end

  # Server design, "Tokens and codes": a code is a secret, so its inspection, which a log or an error can show, leaves
  # the characters out.
  def test_inspect_leaves_the_characters_out
    assert_equal("#<Proof::OneTimeCode>", Proof::OneTimeCode.parse("Q8MR-2T4W").inspect)
  end
end
