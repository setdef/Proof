# frozen_string_literal: true

require_relative("../test_helper")
require "proof/testing"
require "sequel"
require "tmpdir"

# What the tests of the store of runs on SQLite share: a store over a file in a folder of its own, a second connection
# to the file as another process would have, and loggers that stand in for another writer.
module SqliteRunsHelper
  FIXTURES = Proof::Testing::RunFixtures
  public_constant(:FIXTURES)

  # The loggers below. Sequel tells a logger about each statement after the statement ran, at `info` when it worked and
  # at `error` when the database refused it.
  class Watcher
    # Ignores a refused statement.
    def error(_statement); end

    # Ignores a slow statement.
    def warn(_statement); end
  end

  # A logger that sleeps after each read. A call that has read is still running when another thread's call reads.
  class Pause < Watcher
    # Pauses after a `SELECT`.
    def info(statement)
      sleep(0.02) if statement.include?("SELECT")
    end
  end

  # A logger that runs an action once, right after the store's next read, as a writer in another process would get in
  # between a call's read and its write.
  class AfterNextRead < Watcher
    # Prepares to run `action` once.
    def initialize(&action)
      super()
      @actions = [action]
    end

    # Runs the action after a `SELECT`, the first time.
    def info(statement)
      @actions.shift&.call if statement.include?("SELECT")
    end
  end

  # The error that `FailingRead` raises.
  class Failure < StandardError
  end

  # A logger that raises an error at its `nth` read, as a statement that fails part way through a write would.
  class FailingRead < Watcher
    # Prepares to raise at the `nth` `SELECT`.
    def initialize(nth)
      super()
      @reads_left = nth
    end

    # Counts each `SELECT`, and raises at the last.
    def info(statement)
      return unless statement.include?("SELECT")

      @reads_left -= 1
      raise(Failure, statement) if @reads_left.zero?
    end
  end

  # A logger that pauses the fiber it runs in after the first statement that has `text`, and so lets another fiber of
  # the same thread run in the middle of a call.
  class YieldingAfter < Watcher
    # Prepares to pause after a statement that has `text`.
    def initialize(text)
      super()
      @text = text
    end

    # Pauses the fiber, the first time.
    def info(statement)
      return unless @text && statement.include?(@text)

      @text = nil
      Fiber.yield
    end
  end

  def setup
    @folder = Dir.mktmpdir("proof-runs")
    @opened = []
  end

  def teardown
    @opened.each(&:close)
    FileUtils.remove_entry(@folder)
  end

  # A store over a file of its own.
  def build_runs
    open_runs(File.join(@folder, "runs-#{@opened.size}.db"))
  end

  # A store over the same file, as after a restart.
  def reopen_runs(runs)
    open_runs(runs.path)
  end

  # A store over a file of its own, with a logger that sleeps after each read, so the contract's two-thread tests
  # overlap their calls.
  def build_runs_pausing_after_reads
    build_runs.tap { |runs| runs.use_logger(Pause.new) }
  end

  # `fact` as the `version`th fact of a run, written through a connection of its own, as another process would.
  def insert(runs, version, fact, id: FIXTURES.id)
    Sequel.sqlite(runs.path) { |database| database[:facts].insert(**Proof::Sqlite::FactRows.row(id, version, fact)) }
  end

  # The number of rows in the file.
  def row_count(runs)
    Sequel.sqlite(runs.path) { |database| database[:facts].count }
  end

  private def open_runs(path)
    Proof::Sqlite::Runs.new(path:).tap { |runs| @opened << runs }
  end
end
