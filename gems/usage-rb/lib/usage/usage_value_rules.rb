# frozen_string_literal: true

module Usage
  module UsageValueRules
    NUMBER = /\A-(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?\z/
    private_constant(:NUMBER)

    def self.refuses_next?(value)
      # NUMBER is usage 7.4.1's `is_number`, with the dash: digits with at most one dot, and a signed exponent.
      FlagWord.flag?(value) && !NUMBER.match?(value)
    end

    def self.refuses_equals?(_value)
      false
    end

    def self.drop(line, switch, value)
      flag = switch.flag
      # usage has no flag `--help=1`: only `--help` itself asks for help.
      return line.give(flag) unless flag.equal?(Flag::HELP)

      line.refuse { |said| said.unknown_flag("#{switch.typed}=#{value}", line.scope.switches) }
    end
  end
end
