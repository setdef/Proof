# frozen_string_literal: true

module Usage
  class Bundle
    def initialize(switches)
      @switches = switches
    end

    def switches
      # usage gives the next word to the last letter that takes a value, and an empty value to those before it.
      last = @switches.rindex(&:takes_value?)
      @switches.each_with_index.map { |switch, index| (switch.takes_value? && index != last) ? switch.emptied : switch }
    end
  end
end
