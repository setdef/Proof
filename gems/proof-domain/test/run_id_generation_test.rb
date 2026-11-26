# frozen_string_literal: true

require_relative("test_helper")

# Checks how a run ID is made from a clock and a source of randomness.
class RunIdGenerationTest < Minitest::Test
  # A clock that says it is a given moment.
  Clock = Data.define(:now)
  private_constant(:Clock)

  # A source of randomness that returns the numbers it was given, in order.
  class ScriptedRandom
    def initialize(*numbers)
      @numbers = numbers
    end

    # The next number.
    def rand(_limit)
      @numbers.shift
    end
  end

  # Server design, "Runs and their records": "Run IDs are the UTC minute of
  # creation and five random characters from Crockford's Base32", and the time
  # and the randomness come in through ports, never from inside the value.
  def test_generate_makes_an_id_from_the_clock_and_the_source
    clock = Clock.new(now: Time.utc(2026, 11, 25, 3, 36, 41))
    id = Proof::RunId.generate(clock:, random: ScriptedRandom.new(20, 3, 13, 8, 23))

    assert_equal("20261125-0336-m3d8q", id.to_s)
  end

  # Glossary, "run": the minute is "in UTC", whatever zone the clock is in.
  def test_generate_counts_the_minute_in_utc
    clock = Clock.new(now: Time.new(2026, 11, 24, 22, 36, 0, "-05:00"))
    id = Proof::RunId.generate(clock:, random: ScriptedRandom.new(20, 3, 13, 8, 23))

    assert_equal("20261125-0336-m3d8q", id.to_s)
  end

  # Ruby's Random is a source, and what it makes is an ID that reads back.
  def test_generate_with_rubys_random_makes_an_id_that_reads_back
    id = Proof::RunId.generate(clock: Clock.new(now: Time.utc(2026, 11, 25, 3, 36)), random: Random.new(1))

    assert_equal(id, Proof::RunId.parse(id.to_s))
  end

  # Glossary, "run": the characters are "random", so two draws are two IDs.
  def test_two_ids_from_one_source_differ
    clock = Clock.new(now: Time.utc(2026, 11, 25, 3, 36))
    random = Random.new(1)

    refute_equal(Proof::RunId.generate(clock:, random:), Proof::RunId.generate(clock:, random:))
  end

  # A source that answers outside the alphabet makes no ID, not a short one.
  def test_a_source_that_answers_outside_the_alphabet_makes_no_id
    clock = Clock.new(now: Time.utc(2026, 11, 25, 3, 36))
    random = ScriptedRandom.new(20, 3, 13, 8, 99)

    assert_raises(Proof::InvalidRandomSourceError) { Proof::RunId.generate(clock:, random:) }
  end
end
