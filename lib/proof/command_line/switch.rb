# frozen_string_literal: true

module Proof
  module CommandLine
    class Switch
      def initialize(flag, values, messages)
        @flag = flag
        @values = values
        @messages = messages
      end

      def specs
        *shorts, long = @flag.switches
        [*shorts, @flag.takes_value? ? "#{long} VALUE" : long.to_s]
      end

      def accept(value)
        name = @flag.name
        return @values.switch(name) unless @flag.takes_value?

        check(value)
        @flag.repeatable? ? @values.append(name, value) : @values.replace(name, value)
      end

      private def check(value)
        spoken = @flag.switches.last.to_s
        choices = @flag.choices
        raise(Mistake, @messages.flag_for_value(spoken, value)) if Tokens.flag?(value)
        return if choices.empty? || !@flag.strict? || choices.include?(value)

        raise(Mistake, @messages.bad_choice(spoken, value, choices))
      end
    end
  end
end
