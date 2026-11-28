# frozen_string_literal: true

module Usage
  class Line
    def initialize(position, words)
      @position = position
      @words = words.dup
      @values = Values.new
    end

    def parsed
      while !help? && (word = @words.shift)
        read(word)
      end
      CommandNeeds.new(@position, @values).parsed
    end

    def scope
      @position.scope
    end

    def refuse(&)
      @position.refuse(&)
    end

    def value_for(typed)
      value = @words.shift
      (value && value != "--") ? value : refuse { |said| said.missing_value(typed) }
    end

    def take(flag, value)
      # usage takes no word that looks like a flag as a value, and only one of a flag's choices when they are strict.
      flag_like = FlagWord.flag?(value)
      return give(flag, value) unless flag_like || !flag.accepts?(value)

      refuse { |said| flag_like ? said.flag_for_value(flag, value) : said.bad_choice(flag, value) }
    end

    def give(flag, value = nil)
      @values.give(flag, value)
    end

    def help?
      @values.help?
    end

    private def read(word)
      # usage reads every word after the first `--` as an argument, a later `--` too.
      return @values.argue(@words.shift(@words.size)) if word == "--"
      return FlagWord.new(word, self).read if FlagWord.flag?(word)
      return @position = @position.descend(word) if @position.branch?

      @values.argue([word])
    end
  end
end
