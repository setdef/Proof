# frozen_string_literal: true

module Proof
  module CommandLine
    class ExampleBlock
      def initialize(item)
        @item = item
      end

      def lines
        [*header, "    $ #{@item.code}", *text]
      end

      private def header
        Array(@item.header).map { |words| "  #{words}" }
      end

      private def text
        Columns.wrap(@item.help.to_s, 70).map { |line| "    #{line}" }
      end
    end
  end
end
