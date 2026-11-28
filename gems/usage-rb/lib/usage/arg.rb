# frozen_string_literal: true

module Usage
  class Arg < Data.define(:name, :help, :help_long, :required, :repeatable)
    def required?
      required
    end

    def repeatable?
      repeatable
    end

    def take(words)
      repeatable ? words : words.first(1)
    end

    def to_s
      label = repeatable ? "#{name}..." : name
      required ? "<#{label}>" : "[#{label}]"
    end

    # @dynamic name, help, help_long, required, repeatable, initialize
  end
end
