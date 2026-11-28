# frozen_string_literal: true

require_relative("test_helper")

# Checks the stricter rules that `value_rules: Usage::StrictValueRules` turns on, so that nothing typed is dropped and every value
# meets one rule.
class UsageParserStrictValueRulesTest < Minitest::Test
  include UsageTestHelper

  # A flag that takes no value refuses one, where usage would drop it.
  def test_a_value_given_to_a_flag_that_takes_none_is_a_mistake
    assert_equal("--json of command list takes no value", mistake("list", "--json=1", value_rules: Usage::StrictValueRules))
    assert_equal("--help of command list takes no value", mistake("list", "--help=1", value_rules: Usage::StrictValueRules))
  end

  # A value that looks like a flag is a mistake after `=` too, where usage takes it.
  def test_a_value_that_looks_like_a_flag_is_a_mistake_after_an_equals_sign
    assert_equal(
      "--file of command add needs a value, and --x looks like a flag",
      mistake("add", "--file=--x", value_rules: Usage::StrictValueRules)
    )
    assert_equal(
      "--file of command add needs a value, and -q looks like a flag",
      mistake("add", "--file=-q", value_rules: Usage::StrictValueRules)
    )
  end

  # A negative number is a mistake as a value, after `=` or after the flag, where usage takes it.
  def test_a_negative_number_is_a_mistake_as_a_value
    expected = "--file of command add needs a value, and -5 looks like a flag"

    assert_equal(
      [expected, expected],
      [mistake("add", "--file=-5", value_rules: Usage::StrictValueRules), mistake("add", "--file", "-5", value_rules: Usage::StrictValueRules)]
    )
  end

  # A line with none of those words reads as it does without the keyword.
  def test_an_ordinary_line_is_read_as_usual
    assert_equal(["x"], parse("add", "--file=x", value_rules: Usage::StrictValueRules).values("file"))
  end
end
