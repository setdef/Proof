# frozen_string_literal: true

module Proof
  module CommandLine
    class Attributes
      def initialize(flags, args, line)
        @slots = flags.map { |flag| FlagSlot.new(flag) } + args.map { |arg| ArgSlot.new(arg) }
        @line = line
      end

      def to_h
        @slots.to_h { |slot| slot.entry(@line) }
      end

      def build(klass, extras)
        attributes = to_h.merge(extras)
        # Steep says `singleton(GlobalFlags) | singleton(Data)` "does not have method `new`", so it can't check that
        # each class takes exactly the attributes the spec's flags and arguments give it. The commands_test file checks
        # that for every command. An interface with `new: (**untyped)` in place of `singleton(Data)` fails with "Params
        # are incompatible".
        # steep:ignore:start
        klass.new(**attributes.slice(*klass.members))
        # steep:ignore:end
      end
    end
  end
end
