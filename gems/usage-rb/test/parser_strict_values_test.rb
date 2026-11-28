# frozen_string_literal: true

require_relative("test_helper")

# Checks the stricter rules that `strict_values: true` turns on, so that nothing typed is dropped and every value
# meets one rule.
class UsageParserStrictValuesTest < Minitest::Test
  include UsageTestHelper

  # A flag that takes no value refuses one, where usage would drop it.
  def test_a_value_given_to_a_flag_that_takes_none_is_a_mistake
    assert_equal("--json of command list takes no value", mistake("list", "--json=1", strict_values: true))
    assert_equal("--help of command list takes no value", mistake("list", "--help=1", strict_values: true))
  end

  # A value that looks like a flag is a mistake after `=` too, where usage takes it.
  def test_a_value_that_looks_like_a_flag_is_a_mistake_after_an_equals_sign
    assert_equal(
      "--file of command add needs a value, and --x looks like a flag",
      mistake("add", "--file=--x", strict_values: true)
    )
    assert_equal(
      "--file of command add needs a value, and -q looks like a flag",
      mistake("add", "--file=-q", strict_values: true)
    )
  end

  # A negative number is a mistake as a value, after `=` or after the flag, where usage takes it.
  def test_a_negative_number_is_a_mistake_as_a_value
    expected = "--file of command add needs a value, and -5 looks like a flag"

    assert_equal(
      [expected, expected],
      [mistake("add", "--file=-5", strict_values: true), mistake("add", "--file", "-5", strict_values: true)]
    )
  end

  # A line with none of those words reads as it does without the keyword.
  def test_an_ordinary_line_is_read_as_usual
    assert_equal(["x"], parse("add", "--file=x", strict_values: true).values("file"))
  end
end
