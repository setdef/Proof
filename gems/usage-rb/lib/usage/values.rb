# frozen_string_literal: true

module Usage
  class Values
    attr_reader :arguments

    def initialize
      @flags = {}
      @arguments = []
      @help = false
    end

    def give(flag, value)
      return @help = true if flag.equal?(Flag::HELP)

      given = @flags[flag] ||= []
      given << value if value
    end

    def argue(words)
      @arguments.concat(words)
    end

    def help?
      @help
    end

    def given?(flag)
      @flags.key?(flag)
    end

    def parsed(command, args)
      Parsed.new(command:, flags: @flags.transform_keys(&:name), args:, help: @help)
    end

    # @dynamic arguments
  end
end
