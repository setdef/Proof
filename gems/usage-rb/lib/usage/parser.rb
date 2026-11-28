# frozen_string_literal: true

require_relative("strict_value_rules")
require_relative("usage_value_rules")

module Usage
  class Parser
    MESSAGES_REFUSED = "messages must be Usage::Messages or a subclass of it"
    private_constant(:MESSAGES_REFUSED)

    def initialize(spec, messages: Messages, value_rules: UsageValueRules)
      @commands = spec.commands
      @messages = (messages <= Messages) ? messages : raise(ArgumentError, MESSAGES_REFUSED)
      @rules = value_rules
    end

    def parse(words)
      start = Position.new(lineage: @commands.at([]), messages: @messages)
      Line.new(start, words, @rules).parsed
    end
  end
end
