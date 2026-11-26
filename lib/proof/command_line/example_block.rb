# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    class ExampleBlock < Data.define(:item)
      # steep:ignore:end
      def lines
        [*header, "    $ #{item.code}", *text]
      end

      private def header
        Array(item.header).map { |words| "  #{words}" }
      end

      private def text
        Columns.wrap(item.help.to_s, 70).map { |line| "    #{line}" }
      end
    end
    private_constant(:ExampleBlock)
  end
end
