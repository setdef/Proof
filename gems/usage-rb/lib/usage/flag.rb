# frozen_string_literal: true

module Usage
  class Flag < Data.define(:name, :short, :long, :value, :help, :help_long, :choices, :requires, :repeatable, :global)
    def repeatable?
      repeatable
    end

    def global?
      global
    end

    def takes_value?
      value.is_a?(String)
    end

    def accepts?(word)
      choices.accepts?(word)
    end

    def switches
      short.map { |letter| "-#{letter}" } + long.map { |word| "--#{word}" }
    end

    # @dynamic name, short, long, value, help, help_long, choices, requires, repeatable, global, initialize
  end
end
