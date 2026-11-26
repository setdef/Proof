# frozen_string_literal: true

require_relative("test_helper")

# Checks what is not a duration, and what Proof says about it.
class TimeLimitRefusedTest < Minitest::Test
  # The start of the message for a timeout that isn't a duration: the forms
  # that work. What the timeout was follows it.
  MESSAGE = "timeout is a duration: a whole number from 1 and then s, m, or h in lowercase, " \
    "with no space, such as \"90s\", \"30m\", or \"2h\", not "
  private_constant(:MESSAGE)

  # Each timeout that has to be refused, as the test names it.
  def assert_refused(timeouts)
    timeouts.each { |text| assert_raises(Proof::InvalidTimeLimitError, text.inspect) { Proof::TimeLimit.read(text) } }
  end

  # Project file reference, "Properties": `timeout` is "A quoted duration, such
  # as `"90s"`, `"30m"`, or `"2h"`", and issue #52 reads a duration as a whole
  # number and one unit, so a duration of two units or with a fraction is refused.
  def test_a_duration_of_two_units_or_with_a_fraction_is_refused
    assert_refused(["1h30m", "1.5h", "0.5m", "1m30s", "1,5h"])
  end

  # Project file reference, "Properties": the examples have no space, so a
  # space anywhere is refused.
  def test_a_space_is_refused
    assert_refused(["90 s", " 90s", "90s ", "90\ts", "90s\n", "\n90s"])
  end

  # Project file reference, "Properties": the examples' units are `s`, `m`,
  # and `h` in lowercase, so another case and another unit are refused.
  def test_a_unit_that_is_not_s_m_or_h_in_lowercase_is_refused
    assert_refused(%w[2H 30M 90S 1d 1w 1ms 1min 1hr 2hours 90sec 1y 5])
  end

  # Project file reference, "Properties": a duration is a number and a unit,
  # so a bare unit, a bare number, and nothing are refused.
  def test_a_duration_needs_both_a_number_and_a_unit
    assert_refused(["s", "h", "90", "", "m30"])
  end

  # Project file reference, "Properties": a duration is "from 1", so zero, a
  # sign, an exponent, and a leading zero are refused.
  def test_a_number_that_is_not_a_whole_number_from_one_is_refused
    assert_refused(%w[0s 0m 0h 00s 01m -1m +1m 1e3s 1_000s 0x10s])
  end

  # A digit that isn't an ASCII digit is not a number.
  def test_a_digit_that_is_not_ascii_is_refused
    assert_refused(["٣0s"])
  end

  # Project file reference, "Mistakes Proof catches": "a value has the wrong
  # type", and `timeout` is "A quoted duration", so a number is refused.
  def test_a_timeout_that_is_not_text_is_refused
    assert_refused([nil, 90, 1.5, :"90s", ["90s"]])
  end

  # A byte string that isn't valid text, as a command line can hold, is not a
  # duration, and raises the time limit's error, not Ruby's.
  def test_a_timeout_with_invalid_bytes_is_refused
    error = assert_raises(Proof::InvalidTimeLimitError) { Proof::TimeLimit.read("9\xFFs") }

    assert_equal(%(#{MESSAGE}"9\\xFFs"), error.message)
  end

  # A string in an encoding that isn't ASCII-compatible, such as UTF-16, is
  # valid text but not a duration, and raises the time limit's error, not Ruby's.
  def test_a_timeout_in_an_encoding_that_is_not_ascii_compatible_is_refused
    assert_refused(["90s".encode(Encoding::UTF_16LE)])
  end

  # Issue #52 proposes that "Proof refuses anything else, listing the forms
  # that work", as the page says of a size: "refuses it with the forms that
  # work", so the message lists the number, the units, and examples.
  def test_the_message_names_the_value_and_the_forms_that_work
    error = assert_raises(Proof::InvalidTimeLimitError) { Proof::TimeLimit.read("1h30m") }

    assert_equal(%(#{MESSAGE}"1h30m"), error.message)
  end
end
