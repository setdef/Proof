# frozen_string_literal: true

require "optparse"

module Proof
  module CommandLine
    class Options
      class Strict < OptionParser
        private def add_officious; end
      end
      private_constant(:Strict)

      def initialize(command, globals)
        @flags = command.own_flags + globals
        @messages = Messages.new(command.path)
        @values = Values.new
      end

      def parse(tokens)
        words = parser.permute(tokens.flat_map { |token| Tokens.expand(token) })
        [@values, words]
      rescue OptionParser::ParseError => e
        raise(Mistake, Failure.new(@messages, @flags).message(e))
      end

      private def parser
        Strict.new.tap { |parser| prepare(parser) }
      end

      private def prepare(parser)
        parser.require_exact = true
        @flags.each { |flag| register(parser, flag) }
        parser.on("-h", "--help") { @values.ask_for_help }
      end

      private def register(parser, flag)
        switch = Switch.new(flag, @values, @messages)
        parser.on(*switch.specs) { |value| switch.accept(value) }
      end
    end
  end
end
