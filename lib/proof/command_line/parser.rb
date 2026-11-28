# frozen_string_literal: true

module Proof
  module CommandLine
    class Parser
      def initialize(spec)
        @spec = spec
        @usage = Usage::Parser.new(spec, messages: Messages)
      end

      def parse(argv)
        line = @usage.parse(argv)
        VersionAsked.of(line) || HelpAsked.of(line) || Builder.new(@spec, line).parsed
      rescue Usage::CommandLineError => e
        HelpAsked.over(e, argv) || raise(Mistake, e.message)
      end
    end
  end
end
