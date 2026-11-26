# frozen_string_literal: true

require "rom"
require "rom-sql"

module Proof
  module Sqlite
    # steep:ignore:start
    class Facts < ROM::Relation[:sql]
      # steep:ignore:end
      schema(:facts, infer: true)

      def of(run_id)
        where(run_id:).order(:version)
      end

      def in_order
        order(:run_id, :version)
      end
    end
  end
end
