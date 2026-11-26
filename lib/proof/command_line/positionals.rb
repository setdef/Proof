# frozen_string_literal: true

module Proof
  module CommandLine
    class Positionals
      def initialize(command, values)
        @args = command.args
        @values = values
        @messages = WordMessages.new(command.path)
      end

      def assign(words)
        left = @args.reduce(words) { |acc, elem| take(elem, acc) }
        raise(Mistake, @messages.extra_word(left.first)) unless left.empty?
      end

      private def take(arg, remaining)
        taken = arg.repeatable? ? remaining : remaining.first(1)
        raise(Mistake, @messages.missing_argument(arg)) if taken.empty? && arg.required?

        @values.assign(arg.name, taken)
        remaining.drop(taken.size)
      end
    end
  end
end
