# frozen_string_literal: true

module Usage
  class Page
    WIDTH = 100
    private_constant(:WIDTH)

    def initialize(spec, command)
      @spec = spec
      @command = command
    end

    def sections
      [
        title,
        Layout.paragraphs(description, WIDTH),
        UsageLine.new(words:, command:).to_s,
        Lists.examples(examples),
        *tables,
        *ending,
      ]
    end

    # Each kind of page reads the spec and the command through these readers, and gives its own about, description,
    # examples, title for the table of commands, and ending.
    private(attr_reader(:spec, :command))

    private def title
      Layout.paragraphs("#{words.join(' ')} - #{about}", WIDTH)
    end

    private def tables
      [
        Lists.commands(commands_title, command.subcommands),
        Lists.arguments(command.args),
        Lists.flags("Flags:", command.own_flags),
        Lists.flags("Global flags:", spec.commands.global_flags(command.path)),
      ]
    end

    private def words
      [spec.bin, *command.path]
    end

    # @dynamic spec, command, about, description, examples, commands_title, ending
  end
end
