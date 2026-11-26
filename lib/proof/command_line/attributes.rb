# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
    class Attributes
      def initialize(flags, args, values)
        @slots = flags.map { |flag| FlagSlot.new(flag) } + args.map { |arg| ArgSlot.new(arg) }
        @values = values
      end

      def to_h
        @slots.to_h { |slot| slot.entry(@values) }
      end
    end
    private_constant(:Attributes)
  end
end
