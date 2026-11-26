# frozen_string_literal: true

require_relative("test_helper")

# Checks Crockford's Base32, the alphabet that run IDs are written in.
class CrockfordTest < Minitest::Test
  # A source of randomness that returns the numbers it was given, in order,
  # and remembers each limit it was asked for.
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

  # Glossary, "run": "Crockford's Base32, which has no `i`, `l`, `o`, or `u`".
  def test_the_alphabet_has_32_symbols_and_none_of_i_l_o_u
    assert_equal(32, Proof::Crockford::ALPHABET.length)
    assert_equal(32, Proof::Crockford::ALPHABET.chars.uniq.length)
    assert_empty(Proof::Crockford::ALPHABET.chars & %w[i l o u])
  end

  # Glossary, "run": the five characters "come from Crockford's Base32", which
  # has the digits and the letters but `i`, `l`, `o`, and `u`.
  def test_the_alphabet_is_the_digits_then_the_letters_but_i_l_o_u
    assert_equal((("0".."9").to_a + ("a".."z").to_a) - %w[i l o u], Proof::Crockford::ALPHABET.chars)
  end

  # Every symbol of the alphabet reads as itself.
  def test_the_symbols_of_the_alphabet_read_as_themselves
    assert_equal(Proof::Crockford::ALPHABET, Proof::Crockford.read(Proof::Crockford::ALPHABET))
  end

  # Glossary, "run": "Proof reads a typed `o` as `0`".
  def test_a_typed_o_is_read_as_zero
    assert_equal("00", Proof::Crockford.read("oO"))
  end

  # Glossary, "run": "Proof reads ... an `i` or `l` as `1`."
  def test_a_typed_i_or_l_is_read_as_one
    assert_equal("1111", Proof::Crockford.read("iIlL"))
  end

  # Crockford's Base32, which the glossary links, reads either case.
  def test_a_typed_capital_reads_as_the_lowercase_symbol
    assert_equal("m3d8q", Proof::Crockford.read("M3D8Q"))
  end

  # Glossary, "run": the alphabet "has no `i`, `l`, `o`, or `u`", and reads
  # only `o`, `i`, and `l` as other symbols, so `u` is outside it.
  def test_a_u_is_outside_the_alphabet
    assert_nil(Proof::Crockford.read("u"))
    assert_nil(Proof::Crockford.read("U"))
  end

  # Nothing but the alphabet and the three typing slips is a symbol.
  def test_anything_else_is_outside_the_alphabet
    ["-", " ", "m3d8q ", "é", "m3d-8q", "\n"].each do |text|
      assert_nil(Proof::Crockford.read(text), text.inspect)
    end
  end

  # Crockford's Base32 reads either case of the ASCII letters only: Unicode
  # lowercasing turns the Kelvin sign (U+212A) into `k`, which a person never
  # typed as one.
  def test_a_character_that_only_unicode_lowercases_to_a_symbol_is_outside_the_alphabet
    assert_nil(Proof::Crockford.read("\u212A"))
    assert_nil(Proof::Crockford.read("m3d\u212A8"))
  end

  # A byte string that isn't valid text, as a command line can hold, is not an error.
  def test_text_that_is_not_valid_is_outside_the_alphabet
    assert_nil(Proof::Crockford.read("m3d\xFF8"))
  end

  # No characters read as no characters.
  def test_nothing_reads_as_nothing
    assert_equal("", Proof::Crockford.read(""))
  end

  # Glossary, "run": "five random characters ... from Crockford's Base32", so
  # each symbol is one of the 32, and `random` draws the one at the number it is given.
  def test_random_draws_the_symbol_at_each_number_the_source_gives
    source = ScriptedRandom.new(20, 3, 13, 8, 23)

    assert_equal("m3d8q", Proof::Crockford.random(5, source))
  end

  # Each symbol is one of 32, so the source is asked for a number below 32.
  def test_random_asks_the_source_for_a_number_below_32_for_each_symbol
    source = ScriptedRandom.new(0, 31, 5)
    Proof::Crockford.random(3, source)

    assert_equal([32, 32, 32], source.limits)
  end

  # The numbers 0 to 31 draw the 32 symbols in order.
  def test_random_draws_every_symbol_of_the_alphabet
    source = ScriptedRandom.new(*(0..31))

    assert_equal(Proof::Crockford::ALPHABET, Proof::Crockford.random(32, source))
  end

  # Ruby's own Random is a source: it answers `rand` with a number below the limit.
  def test_ruby_random_is_a_source
    drawn = Proof::Crockford.read(Proof::Crockford.random(50, Random.new(3)))

    assert_equal(50, drawn.length)
  end
end
