# frozen_string_literal: true

module Proof
  module CommandLine
    class Branch
      def initialize(command)
        @command = command
        @messages = WordMessages.new(command.path)
      end

      def parse(tail)
        raise(Mistake, @messages.extra_word(tail.first)) unless tail.empty?
        raise(Mistake, @messages.needs_subcommand(@command.subcommand_names)) if @command.subcommand_required?

        HelpRequest.new(path: @command.path)
      end
    end
  end
end
