# frozen_string_literal: true

require_relative("support/sqlite_runs_helper")

# Checks what the store of runs does when another writer gets in between its read and its write, when a write fails
# part way, when two fibers use it, and when the file's lock is held.
class SqliteRunsRacesTest < Minitest::Test
  include SqliteRunsHelper

  # A writer that reads and then loses the race gets the error the contract names, and nothing it wrote is stored.
  def test_a_fact_added_between_the_read_and_the_write_changes_the_run
    runs = FIXTURES.storing(build_runs, FIXTURES.run)
    runs.use_logger(AfterNextRead.new { insert(runs, 2, Proof::Run::CancelAsked.new(at: FIXTURES::AT)) })

    assert_raises(Proof::RunChangedError) { runs.append(FIXTURES.id, FIXTURES.placed, version: 1) }
    assert_equal([Proof::Run::Queued, Proof::Run::CancelAsked], FIXTURES.facts(runs).map(&:class))
  end

  def test_a_placement_added_between_the_read_and_the_write_is_a_second_placement
    runs = FIXTURES.storing(build_runs, FIXTURES.run)
    runs.use_logger(AfterNextRead.new { insert(runs, 2, FIXTURES.placed(runner: "pc-wsl")) })

    assert_raises(Proof::RunAlreadyPlacedError) { runs.append(FIXTURES.id, FIXTURES.placed, version: 1) }
    assert_equal(["pc-wsl"], FIXTURES.facts(runs).filter_map { |fact| fact.runner if fact.is_a?(Proof::Run::Placed) })
  end

  # Architecture, "Storage": each write is one transaction, so a write that fails after its insert leaves nothing.
  def test_a_write_that_fails_part_way_leaves_nothing
    runs = build_runs
    runs.use_logger(FailingRead.new(1))

    assert_raises(Failure) { runs.add(FIXTURES.run) }
    assert_equal(0, row_count(runs))
  end

  def test_an_append_that_fails_part_way_leaves_nothing
    runs = FIXTURES.storing(build_runs, FIXTURES.run)
    runs.use_logger(FailingRead.new(2))

    assert_raises(Failure) { runs.append(FIXTURES.id, FIXTURES.placed, version: 1) }
    assert_equal(1, row_count(runs))
  end

  # Architecture, "Storage": "Without `fiber_concurrency`, runs were placed twice." A fiber holds a connection of its
  # own, so a write that one fiber has begun and not committed is invisible to another fiber of the same thread.
  def test_a_fiber_does_not_see_the_uncommitted_write_of_another_fiber
    runs = build_runs
    writing = Fiber.new { runs.add(FIXTURES.run) }
    runs.use_logger(YieldingAfter.new("INSERT"))
    writing.resume

    assert_nil(runs.find(FIXTURES.id))
    writing.resume

    assert_equal(FIXTURES.run.facts, FIXTURES.facts(runs))
  end

  # Architecture, "Storage": "a busy handler that sleeps make a write waiting on a lock let other fibers run." A
  # thread that waits for the file's write lock sleeps in Ruby, so another thread keeps running.
  def test_a_write_that_waits_for_the_lock_lets_other_threads_run
    runs = build_runs
    held = holding_the_write_lock(runs.path, 0.3)

    assert_operator(ticks_while { runs.add(FIXTURES.run) }, :>, 5)
    assert_equal(FIXTURES.run.facts, FIXTURES.facts(runs))
    held.join
  end

  # How many times a thread that sleeps for 10 milliseconds between ticks ran while the block ran.
  private def ticks_while
    ticks = Thread::Queue.new
    ticker = Thread.new { ticking(ticks) }
    yield
    ticker.kill
    ticks.size
  end

  private def ticking(ticks)
    loop do
      ticks << :tick
      sleep(0.01)
    end
  end

  # A thread that holds the file's write lock for `seconds`, and a promise that it holds it when this returns.
  private def holding_the_write_lock(path, seconds)
    locked = Thread::Queue.new
    holder = Thread.new { hold_the_write_lock(path, locked, seconds) }
    locked.pop
    holder
  end

  private def hold_the_write_lock(path, locked, seconds)
    Sequel.sqlite(path) do |database|
      database.transaction(mode: :immediate) do
        locked << :locked
        sleep(seconds)
      end
    end
  end
end
