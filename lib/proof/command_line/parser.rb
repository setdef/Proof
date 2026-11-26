# frozen_string_literal: true

module Proof
  module CommandLine
    class Parser
      HELP = ["-h", "--help"].freeze
      private_constant(:HELP)

      def self.split(argv)
        index = argv.index("--") || argv.size
        [argv.first(index), argv.drop(index + 1)]
      end

      def initialize(spec)
        @spec = spec
      end

      def parse(argv)
        head, tail = self.class.split(argv)
        command, tokens = Resolver.new(@spec).resolve(head)
        return HelpRequest.new(path: command.path) if tokens.intersect?(HELP)

        command.subcommands.empty? ? Leaf.new(@spec, command).parse(tokens, tail) : Branch.new(command).parse(tail)
      end
    end
  end
end
