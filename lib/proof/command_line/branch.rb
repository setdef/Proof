# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
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
    private_constant(:Branch)
  end
end
