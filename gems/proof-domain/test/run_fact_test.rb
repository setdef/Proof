# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("test_helper")

# Checks what every one of a run's facts has: the moment it was recorded.
class RunFactTest < Minitest::Test
  include RunFacts

  # Server design, "Runs and their records": "Times are recorded from the
  # server's clock", so each fact keeps the moment it was given, in UTC.
  def test_a_fact_keeps_its_time_in_utc
    fact = Proof::Run::CommandStarted.new(at: Time.new(2026, 11, 25, 4, 36, 30, "+01:00"))

    assert_equal(Time.utc(2026, 11, 25, 3, 36, 30), fact.at)
    assert_predicate(fact.at, :utc?)
  end

  # A Time can change its zone in place, so a fact keeps a frozen copy.
  def test_a_fact_keeps_a_frozen_copy_of_its_time
    given = Time.new(2026, 11, 25, 4, 36, 0, "+01:00")
    fact = Proof::Run::CancelAsked.new(at: given)

    assert_predicate(fact.at, :frozen?)
    refute_predicate(given, :frozen?)
    refute_same(given, fact.at)
  end

  # Every fact checks its time, whatever else it holds.
  def test_a_time_that_is_not_a_time_is_refused_by_every_fact
    builders = [
      -> { Proof::Run::CommandStarted.new(at: "now") },
      -> { Proof::Run::Placed.new(at: nil, host: "nuc", runner: "nuc-linux") },
      -> { Proof::Run::Lost.new(at: 1_764_041_760) },
    ]
    builders.each do |builder|
      error = assert_raises(Proof::InvalidFactError, &builder)

      assert_match(/\Aa fact's time is a Time, not /, error.message)
    end
  end

  # Every fact is one of a run's facts, which a run checks for.
  def test_every_fact_is_a_fact
    facts = [queued, placed, started, exited, output, kept, not_kept, cancel, ended(:lost), processes_ended]

    assert(facts.all?(Proof::Run::Fact))
  end

  # A fact is a value: two facts with the same members are equal.
  def test_facts_with_the_same_members_are_equal
    assert_equal(placed, placed)
    refute_equal(placed(runner: "pc-wsl"), placed)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_errors_are_proof_errors
    assert_operator(Proof::InvalidFactError, :<, Proof::Error)
    assert_operator(Proof::InvalidRunError, :<, Proof::Error)
  end
end
