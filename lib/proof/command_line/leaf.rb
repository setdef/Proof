# frozen_string_literal: true

module Proof
  module CommandLine
    class Leaf
      def initialize(spec, command)
        @spec = spec
        @command = command
        @path = command.path
      end

      def parse(tokens, tail)
        values, words = Options.new(@command, @spec.root.global_flags).parse(tokens)
        return HelpAsked.new(path: @path) if values.help?

        verify(values, words, tail)
        Builder.new(@spec, @command, values).parsed
      end

      private def verify(values, words, tail)
        Positionals.new(@command, values).assign(words + tail)
        Checks.new(@command, values).verify
        values.assign_tasks(Tasks.read(words, tail, @path)) if @path == ["run"]
      end
    end
  end
end
