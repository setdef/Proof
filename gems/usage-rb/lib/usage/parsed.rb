# frozen_string_literal: true

module Usage
  class Parsed < Data.define(:command, :flags, :args, :separated, :help)
    def help?
      help
    end

    def given?(name)
      flags.key?(name)
    end

    def value(name)
      values(name).last
    end

    def values(name)
      flags.fetch(name, [])
    end

    def words(name)
      args.fetch(name, [])
    end

    # @dynamic command, flags, args, separated, help, initialize
  end
end
