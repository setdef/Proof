# frozen_string_literal: true

module Usage
  class Line
    attr_reader :rules

    def initialize(position, words, rules)
      @position = position
      @words = words.dup
      @rules = rules
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

    def take(flag, candidate)
      value = candidate.text
      return refuse { |said| said.flag_for_value(flag, value) } if candidate.refused_by?(@rules)

      choose(flag, value)
    end

    def give(flag, value = nil)
      @values.give(flag, value)
    end

    def help?
      @values.help?
    end

    private def choose(flag, value)
      # A flag takes only one of its choices when they are strict.
      return give(flag, value) if flag.accepts?(value)

      refuse { |said| said.bad_choice(flag, value) }
    end

    private def read(word)
      # usage reads every word after the first `--` as an argument, a later `--` too.
      return @values.separate(@words.shift(@words.size)) if word == "--"
      return FlagWord.new(word, self).read if FlagWord.flag?(word)
      return @position = @position.descend(word) if @position.branch?

      @values.argue([word])
    end

    # @dynamic rules
  end
end
