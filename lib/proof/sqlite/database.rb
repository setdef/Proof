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
        # SQLite's own wait sleeps inside C and holds every other thread and fiber.
        connection.busy_handler do |attempts|
          sleep(0.005)
          attempts < 1000
        end
        connection.journal_mode = "wal"
      end
      private_constant(:MIGRATIONS, :ON_CONNECT)

      def self.open(path)
        # A fiber is the unit that holds a connection, as a thread is by default. Two fibers of one thread would share
        # a connection, and so a transaction, and a write could undo another's.
        Sequel.extension(:fiber_concurrency)
        configuration = ROM::Configuration.new(
          :sql, Sequel.sqlite(path, after_connect: ON_CONNECT), migrator: { path: MIGRATIONS }
        )
        configuration.register_relation(Facts)
        configuration.gateways[:default].run_migrations
        ROM.container(configuration)
      end
    end
  end
end
