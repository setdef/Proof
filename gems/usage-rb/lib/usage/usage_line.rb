# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class UsageLine < Data.define(:words, :command)
    # steep:ignore:end
    def to_s
      "Usage: #{[*words, '[FLAGS]', subcommand, *command.args.map(&:to_s)].compact.join(' ')}"
    end

    private def subcommand
      (command.subcommand_required? ? "<SUBCOMMAND>" : "[COMMAND]") unless command.subcommands.empty?
    end
  end
end
