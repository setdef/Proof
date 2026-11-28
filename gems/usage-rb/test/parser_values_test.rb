# frozen_string_literal: true

require_relative("test_helper")

# Checks the words that usage 7.4.1 reads one way and the stricter rules read another: a value given with `=` to a flag
# that takes none, a value that looks like a flag after `=`, and a negative number as the value a flag requires.
class UsageParserValuesTest < Minitest::Test
  include UsageTestHelper

  # usage drops a value attached to a flag that takes none, and sets the flag.
  def test_a_value_given_to_a_flag_that_takes_none_is_dropped
    parsed = parse("list", "--json=1", strict_values: false)

    assert_equal([true, nil], [parsed.given?("json"), parsed.value("json")])
  end

  # usage has no flag `--help=1`: only `--help` itself asks for help.
  def test_a_value_given_to_the_help_flag_names_no_flag
    assert_equal("command list has no flag --help=1", mistake("list", "--help=1", strict_values: false))
  end

  # usage binds what follows `=` to the flag, whatever it looks like.
  def test_a_value_that_looks_like_a_flag_is_taken_after_an_equals_sign
    values = %w[--file=--x --file=-q --file=-5].map { |word| parse("add", word, strict_values: false).value("file") }

    assert_equal(["--x", "-q", "-5"], values)
  end

  # usage takes a negative number as the value that a flag requires.
  def test_a_negative_number_is_the_value_of_the_flag_before_it
    numbers = %w[-5 -1.5 -.5 -5. -1e3 -1E+3 -1.5e-3]
    values = numbers.map { |number| parse("add", "--file", number, strict_values: false).value("file") }

    assert_equal(numbers, values)
  end

  # Only digits, one dot, and an exponent are a number: usage reads `-inf` and `-1e` as flags.
  def test_a_word_that_only_looks_like_a_number_is_a_flag
    words = %w[-inf -1e -1.2.3 -1e5e5 -0x1]

    assert_equal(
      words.map { |word| "--file of command add needs a value, and #{word} looks like a flag" },
      words.map { |word| mistake("add", "--file", word, strict_values: false) }
    )
  end

  # A letter after one that takes a value is a flag of its own, so `-f5` is not `-f` with the number `-5`.
  def test_a_letter_after_one_that_takes_a_value_is_no_number
    assert_equal(
      "--file of command add needs a value, and -5 looks like a flag",
      mistake("add", "-f5", strict_values: false)
    )
  end

  # A word that looks like a flag stays no value when it follows the flag.
  def test_a_word_that_looks_like_a_flag_is_no_value_after_the_flag
    assert_equal(
      "--file of command add needs a value, and --x looks like a flag",
      mistake("add", "--file", "--x", strict_values: false)
    )
  end
end
