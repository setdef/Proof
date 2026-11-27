# frozen_string_literal: true

require "json"
require_relative("row_reader")

module Proof
  module Sqlite
    module FactRows
      KINDS = Run.constants.to_h { |name| [name.name, Run.const_get(name)] }
        .select { |_name, kind| kind.is_a?(Class) && kind < Run::Fact }
        .freeze
      MEMBER_COLUMNS = %i[position os labels cpus megabytes host runner exit_status signal bytes reason].freeze
      public_constant(:KINDS, :MEMBER_COLUMNS)

      def self.row(id, version, fact)
        at = fact.at
        # A row has every column that a member can fill, because a multi-row insert takes its columns from the first row
        # and drops the rest.
        {
          **MEMBER_COLUMNS.to_h { |column| [column, nil] },
          run_id: id.to_s,
          version:,
          kind: kind(fact),
          at_seconds: at.tv_sec,
          at_nanoseconds: at.nsec,
          **columns(fact),
        }
      end

      def self.fact(row)
        RowReader.fact(row)
      end

      def self.kind(fact)
        fact.class.name.to_s.split("::").last.to_s
      end

      def self.columns(fact)
        fact.to_h.except(:at)
          .flat_map { |member, value| columns_of(member, value).to_a }
          .to_h
      end

      def self.columns_of(member, value)
        case value
        when Set then { member => json(value.map(&:to_s)) }
        when LabelSet then { member => json(value.labels.map(&:name)) }
        when Resources then value.to_h
        when Symbol then { member => value.name }
        else { member => value }
        end
      end

      def self.json(names)
        JSON.generate(names.sort)
      end

      private_class_method(:columns, :columns_of, :json)
    end
  end
end
