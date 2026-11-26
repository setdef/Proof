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
        usage,
        Rows.examples(examples),
        *Tables.new(@command, @spec.commands.global_flags(@command.path)).all,
        *ending,
      ]
    end

    # CommandPage reads the command through this reader, so it depends on no instance variable of Page.
    private(attr_reader(:command))

    private def title
      Layout.paragraphs("#{[@spec.bin, *@command.path].join(' ')} - #{about}", WIDTH)
    end

    private def usage
      subcommands = (@command.subcommand_required? ? "<SUBCOMMAND>" : "[COMMAND]") unless @command.subcommands.empty?
      "Usage: #{[@spec.bin, *@command.path, '[FLAGS]', subcommands, *@command.args.map(&:to_s)].compact.join(' ')}"
    end

    private def about
      @spec.about
    end

    private def description
      @spec.about_long
    end

    private def examples
      @spec.examples
    end

    private def ending
      [Rows.exit_statuses(@spec.exit_codes), @spec.after_help]
    end
  end
end
