# frozen_string_literal: true

require_relative("test_helper")

# Checks what is not a duration for a setting, and what Proof says about it.
class DurationRefusedTest < Minitest::Test
  DAYS = %i[d].freeze
  TIME = %i[s m h].freeze
  private_constant(:DAYS, :TIME)

  # Each text that has to be refused for a setting in these units, as the test names it.
  def assert_refused(texts, units: TIME)
    texts.each do |text|
      assert_raises(Proof::InvalidDurationError, text.inspect) { Proof::Duration.read(text, units:, name: "poll") }
    end
  end

  # The message of the refusal of this text, for a setting in these units.
  def refusal(text, units: TIME, name: "poll")
    error = assert_raises(Proof::InvalidDurationError) { Proof::Duration.read(text, units:, name:) }
    error.message
  end

  # Pool file reference, "`retention`": each value is "a quoted duration in days", so minutes, seconds, and hours are
  # refused there, and days are refused where a setting takes seconds, minutes, or hours.
  def test_a_unit_that_the_setting_does_not_take_is_refused
    assert_refused(%w[90m 90s 2h], units: DAYS)
    assert_refused(%w[1d 7d], units: TIME)
  end

  # Issue #52 proposes "a whole number from 1 and one unit", so two units and a fraction are refused.
  def test_a_duration_of_two_units_or_with_a_fraction_is_refused
    assert_refused(["1h30m", "1.5h", "0.5m", "1m30s", "1,5h"])
    assert_refused(["1d12h", "1.5d"], units: DAYS)
  end

  # The same proposal reads a duration "in lowercase, with no space", so a space anywhere and another case are refused.
  def test_a_space_or_another_case_is_refused
    assert_refused(["5 m", " 5m", "5m ", "5\tm", "5m\n", "\n5m", "5M", "5S", "2H"])
    assert_refused(["90D", "90 d", " 90d"], units: DAYS)
  end

  # The same proposal: a duration is a number and a unit, so a bare unit, a bare number, and nothing are refused.
  def test_a_duration_needs_both_a_number_and_a_unit
    assert_refused(["m", "5", "", "m5"])
    assert_refused(["d", "90", ""], units: DAYS)
  end

  # The same proposal: a number "from 1", so zero, a sign, an exponent, and a leading zero are refused.
  def test_a_number_that_is_not_a_whole_number_from_one_is_refused
    assert_refused(%w[0s 0m 0h 00s 01m -1m +1m 1e3s 1_000s 0x10s])
    assert_refused(%w[0d 01d -1d +1d 1e2d], units: DAYS)
  end

  # A digit that isn't an ASCII digit is not a number.
  def test_a_digit_that_is_not_ascii_is_refused
    assert_refused(["٣0s"])
  end

  # Project file reference, "Mistakes Proof catches", which the pool file reference points to: "a value has the wrong
  # type", so a number, `nil`, and a symbol are refused.
  def test_a_value_that_is_not_text_is_refused
    assert_refused([nil, 5, 1.5, :"5m", ["5m"]])
    assert_refused([nil, 90, :"90d"], units: DAYS)
  end

  # A byte string that isn't valid text, as a file can hold, raises the duration's error, not Ruby's.
  def test_a_text_with_invalid_bytes_is_refused
    assert_equal(
      "poll is a duration: a whole number from 1 and then s, m, or h in lowercase, with no space, " \
        "such as \"90s\", \"30m\", or \"2h\", not \"9\\xFFs\"",
      refusal("9\xFFs")
    )
  end

  # A string in an encoding that isn't ASCII-compatible, such as UTF-16, raises the duration's error, not Ruby's.
  def test_a_text_in_an_encoding_that_is_not_ascii_compatible_is_refused
    assert_refused(["5m".encode(Encoding::UTF_16LE)])
  end

  # Pool file reference, "Sizes and labels": a mistake in a value is refused "with the forms that work in the
  # message", so the message names the setting, the units it takes, an example of each, and what it got.
  def test_the_message_names_the_setting_the_forms_that_work_and_the_value
    assert_equal(
      "retention runs is a duration: a whole number from 1 and then d in lowercase, with no space, " \
        "such as \"30d\", not \"1.5d\"",
      refusal("1.5d", units: DAYS, name: "retention runs")
    )
    assert_equal(
      "active-for is a duration: a whole number from 1 and then s, m, or h in lowercase, with no space, " \
        "such as \"90s\", \"30m\", or \"2h\", not \"5 m\"",
      refusal("5 m", name: "active-for")
    )
  end

  # The message lists the units in the order the caller gives them, and joins two with "or" and no comma.
  def test_the_message_joins_two_units_with_or
    assert_equal(
      "poll is a duration: a whole number from 1 and then m or h in lowercase, with no space, " \
        "such as \"30m\" or \"2h\", not 5",
      refusal(5, units: %i[m h])
    )
  end
end
