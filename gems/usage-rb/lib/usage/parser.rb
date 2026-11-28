# frozen_string_literal: true

require_relative("strict_value_rules")
require_relative("usage_value_rules")

module Usage
  class Parser
    RULES = { true => StrictValueRules, false => UsageValueRules }.freeze
    private_constant(:RULES)

    def initialize(spec, messages: Messages, strict_values: false)
      @commands = spec.commands
      @messages = messages
      @rules = RULES[strict_values]
    end

    def parse(words)
      start = Position.new(lineage: @commands.at([]), messages: @messages)
      Line.new(start, words, @rules).parsed
    end
  end
end
