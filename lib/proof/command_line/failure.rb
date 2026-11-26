# frozen_string_literal: true

require "optparse"

module Proof
  module CommandLine
    class Failure
      def initialize(messages, flags)
        @messages = messages
        @switches = flags.flat_map(&:switches)
      end

      def message(error, tokens)
        switch = Tokens.named(error.args.first.to_s, tokens)
        case error
        when OptionParser::MissingArgument then @messages.missing_value(switch)
        when OptionParser::NeedlessArgument then @messages.needless_value(switch)
        else @messages.unknown_flag(switch, Suggestions.for(switch, @switches))
        end
      end
    end
  end
end
