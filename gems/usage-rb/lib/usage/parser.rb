# frozen_string_literal: true

require_relative("strict_value_rules")
require_relative("usage_value_rules")

module Usage
  class Parser
    def initialize(spec, messages: Messages, value_rules: UsageValueRules)
      @commands = spec.commands
      @messages = messages
      @rules = value_rules
    end

    def parse(words)
      start = Position.new(lineage: @commands.at([]), messages: @messages)
      Line.new(start, words, @rules).parsed
    end
  end
end
