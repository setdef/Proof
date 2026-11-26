# frozen_string_literal: true

module Proof
  module CommandLine
    module Profiles
      class Program
        def initialize(spec)
          @spec = spec
        end

        def title
          "#{@spec.bin} - #{@spec.about}"
        end

        def description
          @spec.about_long
        end

        def examples
          @spec.examples
        end

        def exit_rows
          @spec.exit_codes.map { |code| Rows::ExitRow.new(code) }
        end

        def ending
          @spec.after_help
        end
      end

      class Subcommand
        def initialize(spec, command)
          @spec = spec
          @command = command
        end

        def title
          "#{[@spec.bin, *@command.path].join(' ')} - #{@command.help}"
        end

        def description
          @command.help_long
        end

        def examples
          @command.examples
        end

        def exit_rows
          []
        end

        def ending
          nil
        end
      end
    end
  end
end
