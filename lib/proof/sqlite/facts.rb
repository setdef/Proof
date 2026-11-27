# frozen_string_literal: true

require "rom"
require "rom-sql"

module Proof
  module Sqlite
    class Facts < ROM::Relation[:sql]
      schema(:facts, infer: true)

      def of(run_id)
        where(run_id:).order(:version)
      end

      def in_order
        order(:run_id, :version)
      end

      # @dynamic where, order, to_a, max, command, transaction, self.schema
    end
  end
end
