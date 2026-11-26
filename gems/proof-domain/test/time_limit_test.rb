# frozen_string_literal: true

require_relative("test_helper")

# Checks the time limit a task asks for, read from a duration.
class TimeLimitTest < Minitest::Test
  # Project file reference, "Properties": `timeout` is "A quoted duration, such
  # as `"90s"`, `"30m"`, or `"2h"`", so each of the three units is read.
  def test_a_duration_is_read_into_seconds
    assert_equal([90, 1800, 7200], %w[90s 30m 2h].map { |text| Proof::TimeLimit.read(text).seconds })
  end

  # Project file reference, "Properties": the built-in default timeout is
  # `"60m"`, so a duration in minutes and the same duration in seconds are one limit.
  def test_two_durations_of_one_length_are_one_time_limit
    assert_equal(Proof::TimeLimit.read("60m"), Proof::TimeLimit.read("3600s"))
    assert_equal(Proof::TimeLimit.read("60m"), Proof::TimeLimit.read("1h"))
  end

  # Project file reference, "With the complete example on this page": `timeout="45m"`
  # is 45 minutes.
  def test_forty_five_minutes_are_2700_seconds
    assert_equal(2700, Proof::TimeLimit.read("45m").seconds)
  end

  # Project file reference, "Properties": a `timeout` is a duration "from 1",
  # as a size's number is whole, so the shortest limit is one second.
  def test_the_shortest_time_limit_is_one_second
    assert_equal(1, Proof::TimeLimit.read("1s").seconds)
    assert_equal(1, Proof::TimeLimit.new(seconds: 1).seconds)
  end

  # A time limit built from a number of seconds holds a whole number from 1.
  def test_seconds_built_directly_are_a_whole_number_from_one
    [0, -1, 1.5, "60", nil].each do |seconds|
      assert_raises(Proof::InvalidTimeLimitError, seconds.inspect) { Proof::TimeLimit.new(seconds:) }
    end
  end

  # The message says what the seconds are and what it got.
  def test_the_message_for_seconds_names_the_value
    error = assert_raises(Proof::InvalidTimeLimitError) { Proof::TimeLimit.new(seconds: 0) }

    assert_equal("a time limit is a whole number of seconds from 1, not 0", error.message)
  end

  # Project file reference, "Several tasks on one command line", table: `timeout`
  # is "The largest of their values", so time limits compare by their length.
  def test_time_limits_compare_by_their_length
    limits = %w[90m 2h 30s].map { |text| Proof::TimeLimit.read(text) }

    assert_equal(Proof::TimeLimit.read("2h"), limits.max)
    assert_equal(Proof::TimeLimit.read("30s"), limits.min)
  end

  # A time limit is equal only to a time limit of the same length.
  def test_a_time_limit_is_not_equal_to_a_number
    refute_equal(Proof::TimeLimit.read("1s"), 1)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidTimeLimitError, :<, Proof::Error)
  end
end
