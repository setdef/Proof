# frozen_string_literal: true

module Proof
  module CommandLine
    class FlagSlot
      def initialize(item)
        @item = item
      end

      def entry(line)
        [member, read(line)]
      end

      private def member
        @item.name.tr("-", "_").to_sym
      end

      private def read(line)
        name = @item.name
        return line.given?(name) unless @item.takes_value?

        @item.repeatable? ? line.values(name) : line.value(name)
      end
    end
  end
end
