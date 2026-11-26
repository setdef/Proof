# frozen_string_literal: true

require_relative("test_helper")

# Checks how long the server keeps what each run leaves, as the pool file's `retention` node gives it.
class RetentionTest < Minitest::Test
  # The duration of this many days.
  def days(count)
    Proof::Duration.read("#{count}d", units: %i[d], name: "retention")
  end

  # Pool file reference, "`retention`": the defaults are `runs` `"90d"`, `output` `"14d"`, and `artifacts` `"7d"`.
  def test_the_defaults_are_90_14_and_7_days
    retention = Proof::Retention.new

    assert_equal([days(90), days(14), days(7)], [retention.runs, retention.output, retention.artifacts])
  end

  # Pool file reference, "A complete example": `retention runs="90d" output="14d" artifacts="7d"` keeps "each run's
  # record for 90 days, its output for 14 days, and its artifacts for 7 days".
  def test_each_value_is_kept_as_given
    retention = Proof::Retention.new(runs: days(30), output: days(3), artifacts: days(2))

    assert_equal([days(30), days(3), days(2)], [retention.runs, retention.output, retention.artifacts])
  end

  # Pool file reference, "Examples", "Keep runs' output longer": `retention output="30d"` leaves "The `runs` and
  # `artifacts` values" at "their defaults".
  def test_a_value_that_is_not_given_keeps_its_default
    expected = Proof::Retention.new(runs: days(90), output: days(30), artifacts: days(7))

    assert_equal(expected, Proof::Retention.new(output: days(30)))
  end

  # Pool file reference, "`retention`": "Each value is a quoted duration in days", so a duration of 90 minutes, or of 25
  # hours, which is not a whole number of days, is refused for each value, and so is anything that is not a duration.
  def test_a_value_that_is_not_a_whole_number_of_days_is_refused
    parts = [["90m", :m], ["25h", :h]].map { |text, unit| Proof::Duration.read(text, units: [unit], name: "poll") }

    %i[runs output artifacts].each do |member|
      parts.each { |part| assert_raises(Proof::InvalidRetentionError, member.to_s) { Proof::Retention.new(member => part) } }
      assert_raises(Proof::InvalidRetentionError, member.to_s) { Proof::Retention.new(member => "90d") }
      assert_raises(Proof::InvalidRetentionError, member.to_s) { Proof::Retention.new(member => nil) }
    end
  end

  # The message names the value, and says what it got.
  def test_the_message_names_the_value
    %w[runs output artifacts].each do |member|
      error = assert_raises(Proof::InvalidRetentionError) { Proof::Retention.new(member.to_sym => "14d") }

      assert_equal("retention #{member} is a duration in whole days, not \"14d\"", error.message)
    end
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidRetentionError, :<, Proof::Error)
  end
end
