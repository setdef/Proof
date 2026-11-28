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
      # With `unknown_flags "error"`, usage reads each letter after one that takes a value as a flag and refuses one
      # that names none, so the rest of a word is no value, as in `-j8`. It gives the next word to the last letter that
      # takes a value, and an empty value to those before it.
      Bundle.new(letters.map { |letter| Switch.new(known("-#{letter}"), "-#{letter}") }).switches
    end

    private def known(typed)
      @scope.flag(typed) || unknown
    end

    private def unknown
      @line.refuse { |said| said.unknown_flag(@word, @scope.switches) }
    end
  end
end
