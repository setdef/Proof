# frozen_string_literal: true

module Proof
  module CommandLine
    class ArgSlot
      def initialize(item)
        @item = item
      end

      def entry(line)
        [member, read(line)]
      end

      private def member
        name = @item.name
        @item.repeatable? ? :"#{name}s" : name.to_sym
      end

      private def read(line)
        words = line.words(@item.name)
        @item.repeatable? ? words : words.first
      end
    end
  end
end
