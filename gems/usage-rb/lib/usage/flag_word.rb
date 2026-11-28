# frozen_string_literal: true

module Usage
  class FlagWord
    def self.flag?(word)
      word.start_with?("-") && word != "-"
    end

    def initialize(word, line)
      @word = word
      @line = line
      @scope = line.scope
    end

    def read
      # usage reads nothing after help.
      switches.each { |switch| switch.read(@line) unless @line.help? }
    end

    private def switches
      return [long] if @word.start_with?("--")

      unknown unless @scope.letters?(@word)
      short(@word.delete_prefix("-").chars)
    end

    private def long
      typed, value = @word.split("=", 2)
      name = typed.to_s
      Switch.long(known(name), name, value)
    end

    private def short(letters)
      letter, following = letters
      switch = letter_switch("-#{letter}", following)
      (following && !switch.takes_value?) ? [switch, *short(letters.drop(1))] : [switch]
    end

    private def letter_switch(typed, following)
      flag = known(typed)
      Switch.letter(flag, typed, following)
    end

    private def known(typed)
      @scope.flag(typed) || unknown
    end

    private def unknown
      @line.refuse { |said| said.unknown_flag(@word, @scope.switches) }
    end
  end
end
