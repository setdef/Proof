# frozen_string_literal: true

require "rom"
require "rom-sql"
require_relative("facts")

module Proof
  module Sqlite
    module Database
      MIGRATIONS = File.join(__dir__.to_s, "migrations")
      ON_CONNECT = lambda do |connection|
        # A connection waits for the file's lock by sleeping in Ruby, so a thread or fiber that waits lets others run.
        # SQLite's own wait, `busy_timeout=`, sleeps inside C and holds every other thread and fiber.
        connection.busy_handler_timeout = 5000
        write_ahead(connection)
      end
      WRITE_AHEAD_ATTEMPTS = 200
      public_constant(:WRITE_AHEAD_ATTEMPTS)
      private_constant(:MIGRATIONS, :ON_CONNECT)

      def self.open(path)
        # A fiber is the unit that holds a connection, as a thread is by default. Two fibers of one thread would share
        # a connection, and so a transaction, and a write could undo another's.
        Sequel.extension(:fiber_concurrency)
        configuration = ROM::Configuration.new(
          :sql, Sequel.sqlite(path, after_connect: ON_CONNECT), migrator: { path: MIGRATIONS }
        )
        configuration.register_relation(Facts)
        migrate(configuration.gateways[:default])
        ROM.container(configuration)
      end

      def self.write_ahead(connection, attempts: WRITE_AHEAD_ATTEMPTS)
        connection.journal_mode = "wal"
      rescue SQLite3::BusyException
        # SQLite refuses a connection that asks for the mode while another connection is changing it, without calling
        # the busy handler, so a file that two processes open as it is made needs another try.
        raise if attempts == 1

        sleep(0.005)
        write_ahead(connection, attempts: attempts - 1)
      end

      def self.migrate(gateway)
        # Two processes that open a new file together would both find it unmigrated, and both create its table or both
        # write the migrator's version. A write lock held from the check to the end of the migrations makes the second
        # wait, and then find nothing to run.
        gateway.connection.transaction(mode: :immediate) { gateway.run_migrations }
      end
      private_class_method(:migrate)
    end
  end
end
