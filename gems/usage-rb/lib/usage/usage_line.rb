# frozen_string_literal: true

module Usage
  class UsageLine < Data.define(:words, :command)
    def to_s
      "Usage: #{[*words, '[FLAGS]', subcommand, *command.args.map(&:to_s)].compact.join(' ')}"
    end

    private def subcommand
      (command.subcommand_required? ? "<SUBCOMMAND>" : "[COMMAND]") unless command.subcommands.empty?
    end

    # @dynamic words, command, initialize
  end
end
