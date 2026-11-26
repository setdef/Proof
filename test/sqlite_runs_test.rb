# frozen_string_literal: true

require_relative("support/sqlite_every_run")
require_relative("support/sqlite_runs_helper")

# Checks that the store of runs on SQLite keeps every promise of the port, with two threads at once and across a
# restart, and that it rebuilds every run it reads.
class SqliteRunsTest < Minitest::Test
  include Proof::Testing::RunsContract
  include SqliteRunsHelper

  # Architecture, "A run as a consistency boundary": "A record changed behind Proof's back therefore fails to load,
  # instead of reporting a pass."
  def test_a_record_changed_behind_its_back_fails_to_load
    runs = FIXTURES.storing(build_runs, FIXTURES.run(later: [FIXTURES.placed]))
    insert(runs, 3, Proof::Run::Succeeded.new(at: FIXTURES::AT))

    assert_raises(Proof::InvalidRunError) { runs.find(FIXTURES.id) }
  end

  # Every query rebuilds every run it reads, so a run that breaks a rule can't hide among the others.
  def test_every_query_rebuilds_every_run
    runs = FIXTURES.storing(build_runs, FIXTURES.run)
    insert(runs, 2, Proof::Run::ProcessesEnded.new(at: FIXTURES::AT))

    assert_raises(Proof::InvalidRunError) { runs.queued }
    assert_raises(Proof::InvalidRunError) { runs.holding_resources }
  end

  # A placed run takes every fact but a second placement.
  def test_a_placed_run_takes_a_fact_that_is_not_a_placement
    runs = FIXTURES.storing(build_runs, FIXTURES.run(later: [FIXTURES.placed]))
    runs.append(FIXTURES.id, Proof::Run::CancelAsked.new(at: FIXTURES::AT), version: 2)

    assert_equal(3, FIXTURES.facts(runs).size)
  end

  def test_two_stores_share_nothing_unless_given_one_file
    FIXTURES.storing(build_runs, FIXTURES.run)

    assert_nil(build_runs.find(FIXTURES.id))
  end

  # Architecture, "Storage": the facts come back from the file as they went in, whichever fact they are.
  def test_a_run_through_every_fact_comes_back_with_every_fact
    runs = build_runs
    SqliteEveryRun::RUNS.each { |run| runs.add(run) }

    assert_equal(SqliteEveryRun::RUNS.map(&:facts), SqliteEveryRun::RUNS.map { |run| runs.find(run.id).facts })
  end

  def test_the_runs_through_every_fact_have_every_kind_of_fact
    kinds = SqliteEveryRun::RUNS.flat_map(&:facts).to_set(&:class)

    assert_equal(Proof::Sqlite::FactRows::KINDS.values.to_set, kinds)
  end

  # Architecture, "Storage": "A fact's `Time` must come back equal, in UTC, to the microsecond or better."
  def test_a_time_comes_back_equal_and_in_utc_from_the_file
    at = Time.new(2026, 11, 25, 4, 36, 0.123456789r, "+01:00")
    runs = FIXTURES.storing(build_runs, FIXTURES.run(later: [Proof::Run::CancelAsked.new(at:)]))
    stored = runs.find(FIXTURES.id).facts.last.at

    assert_equal([at.getutc, true], [stored, stored.utc?])
  end
end
