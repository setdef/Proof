# frozen_string_literal: true

require "json"

module Proof
  module Sqlite
    module RowReader
      UNKNOWN_KIND = "a stored fact is of no kind that a run has, not %p"
      READERS = {
        os: -> (row) { JSON.parse(String(row[:os])).map { |name| OS.new(name:) } },
        labels: -> (row) { LabelSet.of(*JSON.parse(String(row[:labels]))) },
        resources: -> (row) { Resources.new(cpus: Integer(row[:cpus]), megabytes: Integer(row[:megabytes])) },
        reason: -> (row) { String(row[:reason]).to_sym },
      }.freeze
      private_constant(:UNKNOWN_KIND, :READERS)

      def self.fact(row)
        name = String(row[:kind])
        kind = FactRows::KINDS[name] || raise(InvalidFactError, format(UNKNOWN_KIND, name))
        kind.new(at: time_of(row), **members_of(kind, row))
      rescue JSON::ParserError, TypeError => e
        raise(InvalidFactError, "a stored fact can't be read: #{e.message}")
      end

      def self.time_of(row)
        Time.at(Integer(row[:at_seconds]), Integer(row[:at_nanoseconds]), :nsec)
      end

      def self.members_of(kind, row)
        (kind.members - [:at]).to_h { |member| [member, read(member, row)] }
      end

      def self.read(member, row)
        READERS.key?(member) ? READERS[member].call(row) : row[member]
      end
      private_class_method(:time_of, :members_of, :read)
    end
  end
end
