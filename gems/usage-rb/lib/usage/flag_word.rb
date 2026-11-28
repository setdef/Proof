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
      @word.start_with?("--") ? long.read(@line) : bundle.read(@line)
    end

    private def bundle
      unknown unless @scope.letters?(@word)
      switches = @scope.named(@word)
      Bundle.new(switches, (-> { unknown } if switches.size < @word.size - 1))
    end

    private def long
      typed, value = @word.split("=", 2)
      name = typed.to_s
      Switch.long(known(name), name, value)
    end

    private def known(typed)
      @scope.flag(typed) || unknown
    end

    private def unknown
      @line.refuse { |said| said.unknown_flag(@word, @scope.switches) }
    end
  end
end
