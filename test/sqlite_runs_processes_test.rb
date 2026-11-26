# frozen_string_literal: true

require_relative("test_helper")
require "rbconfig"
require "tmpdir"

# Checks what the store of runs does when several processes open one new file at the same moment, as the server and a
# command on the same computer would.
class SqliteRunsProcessesTest < Minitest::Test
  LIB = File.expand_path("../lib", __dir__)
  PROCESSES = 6
  ROUNDS = 3
  # Loads everything, says it is ready, waits for its input to close, and then opens the store and says how it went.
  CHILD = <<~RUBY
    require("proof")
    require("sqlite3")
    Proof::Sqlite::Runs
    puts("ready")
    $stdout.flush
    $stdin.read
    begin
      Proof::Sqlite::Runs.new(path: ARGV.fetch(0)).close
      puts("opened")
    rescue StandardError => error
      puts("\#{error.class}: \#{error.message}")
    end
  RUBY
  private_constant(:LIB, :PROCESSES, :ROUNDS, :CHILD)

  # Architecture, "Storage": "A migration runs under the file's write lock": every process that opens a new file at
  # once opens it, and none finds it half made.
  def test_processes_opening_one_new_file_at_once_all_open_it
    outcomes = Array.new(ROUNDS) { open_together }
      .flatten

    assert_equal(["opened"] * (PROCESSES * ROUNDS), outcomes)
  end

  # What each of `PROCESSES` new processes says after they all open a store over one new file at once.
  private def open_together
    Dir.mktmpdir("proof-runs") do |folder|
      children = Array.new(PROCESSES) { start(File.join(folder, "runs.db")) }
      children.each(&:gets)
      children.each(&:close_write)
      children.map { |child| child.read.chomp.tap { child.close } }
    end
  end

  private def start(path)
    IO.popen([RbConfig.ruby, "-I", LIB, "-e", CHILD, path], "r+", err: %i[child out])
  end
end
