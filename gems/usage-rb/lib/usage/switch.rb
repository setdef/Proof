# frozen_string_literal: true

module Usage
  class Switch
    attr_reader :flag, :typed

    def self.long(flag, typed, value)
      new(flag, typed, (AfterEquals.new(value) if value))
    end

    def self.letter(flag, typed, following)
      # usage reads the letter after one that takes a value as a flag of its own, so it is no value of that flag.
      new(flag, typed, (LetterAfter.new("-#{following}") if following && flag.takes_value?))
    end

    def initialize(flag, typed, attached = nil)
      @flag = flag
      @typed = typed
      @attached = attached
    end

    def takes_value?
      flag.takes_value?
    end

    def read(line)
      return line.take(flag, @attached || NextWord.new(line.value_for(typed))) if takes_value?

      attached = @attached
      attached ? line.rules.drop(line, self, attached.text) : line.give(flag)
    end

    # @dynamic flag, typed
  end
end
