# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("test_helper")
require "proof/testing"

# Checks that the in-memory store of runs keeps every promise of the port.
class InMemoryRunsTest < Minitest::Test
  include Proof::Testing::RunsContract
  include RunFacts

  # A table of facts that sleeps after each lookup, so a call that has read
  # the table is still running when another thread's call reads it.
  class SlowTable < Hash
    # The facts under `key`, after a pause.
    def [](key)
      slowly { super }
    end

    # Whether `key` is stored, after a pause.
    def key?(key)
      slowly { super }
    end

    # Every stored run's facts mapped, after a pause.
    def map(&)
      slowly { super }
    end

    private def slowly
      found = yield
      sleep(0.02)
      found
    end
  end

  # A fresh store.
  def build_runs
    Proof::InMemory::Runs.new
  end

  # A store over a table that sleeps after each lookup, so the contract's
  # two-thread tests overlap their calls.
  def build_runs_pausing_after_reads
    Proof::InMemory::Runs.new(records: SlowTable.new)
  end

  # A store over the same Hash, as after a restart.
  def reopen_runs(runs)
    Proof::InMemory::Runs.new(records: runs.records)
  end

  # Architecture, "A run as a consistency boundary": "A record changed behind
  # Proof's back therefore fails to load, instead of reporting a pass."
  def test_a_record_changed_behind_its_back_fails_to_load
    runs = build_runs
    runs.add(run_of(*ran))
    runs.records[ID] = [*ran, ended(:succeeded)]

    assert_raises(Proof::InvalidRunError) { runs.find(ID) }
  end

  # A run that breaks a rule can't be stored through the store's own records,
  # because every query rebuilds every run.
  def test_every_query_rebuilds_every_run
    runs = build_runs
    runs.add(run_of(queued))
    runs.records[ID] = [placed]

    assert_raises(Proof::InvalidRunError) { runs.queued }
  end

  # Each store keeps its own runs unless it is given another's records.
  def test_two_stores_share_nothing_unless_given_one_records
    first = build_runs
    first.add(run_of(queued))

    assert_nil(build_runs.find(ID))
  end
end
