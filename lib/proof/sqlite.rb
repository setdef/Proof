# frozen_string_literal: true

module Proof
  module Sqlite
    autoload(:RowReader, File.join(__dir__.to_s, "sqlite/row_reader.rb"))
    autoload(:FactRows, File.join(__dir__.to_s, "sqlite/fact_rows.rb"))
  end
end
