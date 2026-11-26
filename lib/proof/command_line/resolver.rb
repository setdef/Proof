# frozen_string_literal: true

module Proof
  module CommandLine
    class Resolver
      def initialize(spec)
        @command = spec.root
        @skipped = []
        @switches = @command.global_flags.flat_map(&:switches) + ["-h", "--help"]
      end

      def resolve(tokens)
        tokens.each { |token| consume(token) }
        [@command, @skipped]
      end

      private def consume(token)
        return @skipped << token if @command.subcommands.empty?

        Tokens.flag?(token) ? skip(token) : descend(token)
      end

      private def skip(token)
        refuse(token) unless @switches.include?(token) || Tokens.cluster?(token, @switches)
        @skipped << token
      end

      private def descend(word)
        @command = @command.subcommand(word) || refuse_word(word)
      end

      private def refuse(token)
        switch = token.split("=").first.to_s
        raise(Mistake, Messages.new(@command.path).unknown_flag(switch, Suggestions.for(switch, @switches)))
      end

      private def refuse_word(word)
        suggestions = Suggestions.for(word, @command.subcommand_names)
        raise(Mistake, WordMessages.new(@command.path).unknown_command(word, suggestions))
      end
    end
  end
end
