# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    class Help
      # steep:ignore:end
      def initialize(spec, command)
        @profile = command.path.empty? ? Profiles::Program.new(spec) : Profiles::Subcommand.new(spec, command)
        @tables = Tables.new(command, spec.root.global_flags, @profile.exit_rows)
        @command = command
        @bin = spec.bin
      end

      def text
        sections = [title, description, usage, examples, *@tables.sections]
        sections << @profile.ending
        "#{sections.compact.join("\n\n")}\n"
      end

      private def title
        Columns.wrap(@profile.title, 100).join("\n")
      end

      private def description
        Columns.paragraphs(@profile.description, 100)
      end

      private def usage
        words = [@bin, *@command.path, "[FLAGS]", subcommands, *@command.args.map(&:to_s)]
        "Usage: #{words.compact.join(' ')}"
      end

      private def subcommands
        return if @command.subcommands.empty?

        @command.subcommand_required? ? "<SUBCOMMAND>" : "[COMMAND]"
      end

      private def examples
        blocks = @profile.examples.flat_map { |example| ExampleBlock.new(example).lines }
        ["Examples:", *blocks].join("\n") unless blocks.empty?
      end
    end
    private_constant(:Help)
  end
end
