# frozen_string_literal: true

module Proof
  module CommandLine
    class HelpAsked < Data.define(:path)
      WORDS = ["-h", "--help"].freeze
      public_constant(:WORDS)

      def self.of(line)
        command = line.command
        # A command with subcommands, given none, prints its help, as `proof` alone does.
        new(path: command.path) if line.help? || !command.subcommands.empty?
      end

      def self.over(error, argv)
        command = error.command
        # clig.dev: on -h or --help, "Ignore any other flags and arguments that are passed", once the words have named
        # a command that runs.
        asked = argv.take_while { |word| word != "--" }
          .intersect?(WORDS)
        new(path: command.path) if asked && command.subcommands.empty?
      end

      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic path, initialize
    end
  end
end
