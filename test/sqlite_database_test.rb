# frozen_string_literal: true

require_relative("test_helper")
require "sqlite3"

# Checks how the file is put in write-ahead mode when SQLite refuses at first.
class SqliteDatabaseTest < Minitest::Test
  # A connection that is busy for its first `busy` requests of a mode, and then takes it.
  class Connection
    attr_reader :modes

    def initialize(busy)
      @busy = busy
      @modes = []
    end

    def journal_mode=(mode)
      @busy -= 1
      raise(SQLite3::BusyException, "database is locked") if @busy >= 0

      @modes << mode
    end
  end

  # Architecture, "Storage": two processes that open a new file together can't both change its mode at once.
  def test_the_mode_is_asked_for_again_while_another_connection_changes_it
    connection = Connection.new(3)
    Proof::Sqlite::Database.write_ahead(connection)

    assert_equal(["wal"], connection.modes)
  end

  def test_a_file_that_stays_busy_raises_after_the_attempts
    connection = Connection.new(3)

    assert_raises(SQLite3::BusyException) { Proof::Sqlite::Database.write_ahead(connection, attempts: 3) }
    assert_empty(connection.modes)
  end

  def test_the_last_attempt_can_succeed
    connection = Connection.new(2)
    Proof::Sqlite::Database.write_ahead(connection, attempts: 3)

    assert_equal(["wal"], connection.modes)
  end
end
