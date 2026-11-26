# frozen_string_literal: true

require_relative("support/sqlite_runs_helper")

# Checks what the store of runs keeps in its file: the unique indexes that refuse a writer that read before another
# wrote, and the file's mode.
class SqliteRunsFileTest < Minitest::Test
  include SqliteRunsHelper

  # Architecture, "Storage": the unique indexes are the store's last refusal of a writer that read before another
  # wrote, so the file refuses a second fact at one version of a run.
  def test_the_file_refuses_two_facts_at_one_version_of_a_run
    runs = FIXTURES.storing(build_runs, FIXTURES.run)

    assert_raises(Sequel::UniqueConstraintViolation) { insert(runs, 1, Proof::Run::CancelAsked.new(at: FIXTURES::AT)) }
  end

  def test_the_file_refuses_two_placements_of_a_run_at_different_versions
    runs = FIXTURES.storing(build_runs, FIXTURES.run(later: [FIXTURES.placed]))
    insert(runs, 3, Proof::Run::CancelAsked.new(at: FIXTURES::AT))

    assert_raises(Sequel::UniqueConstraintViolation) { insert(runs, 4, FIXTURES.placed(runner: "nuc-wsl")) }
  end

  def test_the_file_refuses_two_queued_facts_at_one_queue_position
    runs = FIXTURES.storing(build_runs, FIXTURES.run)

    assert_raises(Sequel::UniqueConstraintViolation) { insert(runs, 1, FIXTURES.queued, id: FIXTURES.id("k7q2w")) }
  end

  # Architecture, "Storage": the file keeps a write from blocking a read, and the mode stays with the file.
  def test_the_file_is_in_write_ahead_mode
    runs = build_runs
    mode = Sequel.sqlite(runs.path) { |database| database["PRAGMA journal_mode"].get(:journal_mode) }

    assert_equal("wal", mode)
  end
end
