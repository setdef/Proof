# frozen_string_literal: true

module Proof
  module CommandLine
    class FlagSlot
      def initialize(item)
        @item = item
      end

      def entry(values)
        [member, read(values)]
      end

      private def member
        @item.name.tr("-", "_").to_sym
      end

      private def read(values)
        name = @item.name
        return values.flag?(name) unless @item.takes_value?

        @item.repeatable? ? values.list(name) : values.text(name)
      end
    end
  end
end
