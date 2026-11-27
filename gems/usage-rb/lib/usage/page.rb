# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Page
    # steep:ignore:end
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
        usage,
        Rows.examples(examples),
        *Tables.new(@command, @spec.commands.global_flags(@command.path)).all,
        *ending,
      ]
    end

    # Each kind of page reads the spec and the command through these readers, and gives its own about, description,
    # examples, and ending.
    private(attr_reader(:spec, :command))

    private def title
      Layout.paragraphs("#{words.join(' ')} - #{about}", WIDTH)
    end

    private def usage
      "Usage: #{[*words, '[FLAGS]', subcommand, *@command.args.map(&:to_s)].compact.join(' ')}"
    end

    private def words
      [@spec.bin, *@command.path]
    end

    private def subcommand
      (@command.subcommand_required? ? "<SUBCOMMAND>" : "[COMMAND]") unless @command.subcommands.empty?
    end
  end
end
