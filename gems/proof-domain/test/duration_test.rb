# frozen_string_literal: true

require_relative("test_helper")

# Checks a duration, which each setting of the pool file reads in the units that setting takes.
class DurationTest < Minitest::Test
  DAYS = %i[d].freeze
  TIME = %i[s m h].freeze
  private_constant(:DAYS, :TIME)

  # The seconds of a duration read in days.
  def in_days(text)
    Proof::Duration.read(text, units: DAYS, name: "retention runs").seconds
  end

  # The seconds of a duration read in seconds, minutes, or hours.
  def in_short(text)
    Proof::Duration.read(text, units: TIME, name: "poll").seconds
  end

  # Pool file reference, "`retention`": "Each value is a quoted duration in days, such as `"30d"`", and the example
  # reads `runs="90d"`, `output="14d"`, and `artifacts="7d"`.
  def test_a_duration_in_days_is_read_into_seconds
    assert_equal([90 * 86_400, 14 * 86_400, 7 * 86_400, 86_400], %w[90d 14d 7d 1d].map { |text| in_days(text) })
  end

  # Pool file reference, "`defaults`": `active-for "5m"`, and "`repository`": the default `poll` is `"1m"`, so seconds,
  # minutes, and hours are read.
  def test_a_duration_in_seconds_minutes_or_hours_is_read_into_seconds
    assert_equal([45, 300, 60, 7200], %w[45s 5m 1m 2h].map { |text| in_short(text) })
  end

  # Issue #52 proposes a whole number "from 1", so the shortest duration is one unit.
  def test_the_shortest_duration_is_one_unit
    assert_equal([1, 60, 3600, 86_400], [in_short("1s"), in_short("1m"), in_short("1h"), in_days("1d")])
  end

  # Pool file reference, "`repository`": a `poll` of `"1m"` is how often the server fetches, so `"1m"` and `"60s"` are
  # one length, and the duration compares by its length.
  def test_two_durations_of_one_length_are_one_duration
    one_minute = Proof::Duration.read("1m", units: TIME, name: "poll")

    assert_equal(Proof::Duration.new(seconds: 60), one_minute)
    assert_equal(Proof::Duration.read("60s", units: TIME, name: "poll"), one_minute)
  end

  # A duration built from a number of seconds holds a whole number from 1.
  def test_seconds_built_directly_are_a_whole_number_from_one
    [0, -1, 1.5, "60", nil].each do |seconds|
      assert_raises(Proof::InvalidDurationError, seconds.inspect) { Proof::Duration.new(seconds:) }
    end
  end

  # The message says what the seconds are and what it got.
  def test_the_message_for_seconds_names_the_value
    error = assert_raises(Proof::InvalidDurationError) { Proof::Duration.new(seconds: 0) }

    assert_equal("a duration is a whole number of seconds from 1, not 0", error.message)
  end

  # A duration is equal only to a duration of the same length.
  def test_a_duration_is_not_equal_to_a_number
    refute_equal(Proof::Duration.new(seconds: 1), 1)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidDurationError, :<, Proof::Error)
  end
end
