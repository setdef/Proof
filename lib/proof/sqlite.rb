# frozen_string_literal: true

module Proof
  module Sqlite
    # The store of runs loads ROM, Sequel, and SQLite, so it loads the first time something names it, and
    # `require "proof"` loads none of them.
    autoload(:Runs, File.join(__dir__.to_s, "sqlite/runs.rb"))
    autoload(:Refusals, File.join(__dir__.to_s, "sqlite/refusals.rb"))
    autoload(:RunRows, File.join(__dir__.to_s, "sqlite/run_rows.rb"))
    autoload(:RowReader, File.join(__dir__.to_s, "sqlite/row_reader.rb"))
    autoload(:FactRows, File.join(__dir__.to_s, "sqlite/fact_rows.rb"))
  end
end
