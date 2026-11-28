# frozen_string_literal: true

module Usage
  class Binding
    def initialize(position, words)
      @position = position
      @words = words
    end

    def to_h
      bound = bound_words
      missing(bound)
      extra(@words.drop(bound.values.sum(&:size)))
      bound
    end

    private def args
      @position.command.args
    end

    private def bound_words
      left = @words
      args.to_h do |arg|
        taken = arg.take(left)
        left = left.drop(taken.size)
        [arg.name, taken]
      end
    end

    private def missing(bound)
      arg = args.find { |each| each.required? && bound.fetch(each.name, []).empty? }
      @position.refuse { |said| said.missing_argument(arg) } if arg
    end

    private def extra(words)
      # A command with subcommands takes no argument, so a word left there came after the dashes.
      word = words.first
      @position.refuse { |said| said.extra_word(word) } if word
    end
  end
end
