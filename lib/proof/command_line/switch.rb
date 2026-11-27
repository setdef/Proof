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
        # OptionParser takes the next word as a value even when it looks like a flag, and its own list of choices
        # completes the front of a choice, where usage refuses both. So the value is checked here.
        spoken = @flag.switches.last.to_s
        raise(Mistake, @messages.flag_for_value(spoken, value)) if Tokens.flag?(value)
        return if @flag.accepts?(value)

        raise(Mistake, @messages.bad_choice(spoken, value, @flag.choices))
      end
    end
  end
end
