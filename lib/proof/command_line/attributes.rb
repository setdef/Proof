# frozen_string_literal: true

module Proof
  module CommandLine
    class Attributes
      def initialize(flags, args, values)
        @slots = flags.map { |flag| FlagSlot.new(flag) } + args.map { |arg| ArgSlot.new(arg) }
        @values = values
      end

      def to_h
        @slots.to_h { |slot| slot.entry(@values) }
      end
    end
  end
end
