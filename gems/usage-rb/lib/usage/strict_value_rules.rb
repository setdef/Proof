# frozen_string_literal: true

module Usage
  module StrictValueRules
    def self.refuses_next?(value)
      FlagWord.flag?(value)
    end

    def self.refuses_equals?(value)
      FlagWord.flag?(value)
    end

    def self.drop(line, switch, _value)
      line.refuse { |said| said.needless_value(switch.typed) }
    end
  end
end
