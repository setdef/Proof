# frozen_string_literal: true

module Usage
  class Page
    WIDTH = 100
    private_constant(:WIDTH)

    def initialize(spec, lineage)
      @spec = spec
      @lineage = lineage
    end

    def sections
      [
        title,
        Layout.paragraphs(description, WIDTH),
        UsageLine.new(words:, command:).to_s,
        Lists.examples("Examples:", examples),
        *tables,
        *ending,
      ]
    end

    # Each kind of page reads the spec and the command through these readers, and gives its own about, description,
    # examples, title for the table of commands, and ending.
    private(attr_reader(:spec, :lineage))

    private def command
      lineage.command
    end

    private def title
      Layout.paragraphs("#{words.join(' ')} - #{about}", WIDTH)
    end

    private def tables
      [
        Lists.commands(commands_title, command.subcommands),
        Lists.arguments("Arguments:", command.args),
        Lists.flags("Flags:", command.own_flags),
        Lists.flags("Global flags:", lineage.global_flags),
      ]
    end

    private def words
      [spec.bin, *command.path]
    end

    # @dynamic spec, lineage, about, description, examples, commands_title, ending
  end
end
