# frozen_string_literal: true

module Usage
  class Flag < Data.define(:name, :short, :long, :value, :help, :help_long, :choices, :requires, :repeatable, :global)
    HELP = new(
      name: "help",
      short: ["h"],
      long: ["help"],
      value: nil,
      help: "Print help",
      help_long: nil,
      choices: Choices.new(values: [], strict: true),
      requires: [],
      repeatable: false,
      global: true
    )
    public_constant(:HELP)

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
