# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    module Profiles
      # steep:ignore:end
      # steep:ignore:start
      class Program < Data.define(:spec)
        # steep:ignore:end
        def title
          "#{spec.bin} - #{spec.about}"
        end

        def description
          spec.about_long
        end

        def examples
          spec.examples
        end

        def exit_rows
          spec.exit_codes.map { |code| Rows::ExitRow.new(code) }
        end

        def ending
          spec.after_help
        end
      end

      # steep:ignore:start
      class Subcommand < Data.define(:spec, :command)
        # steep:ignore:end
        def title
          "#{[spec.bin, *command.path].join(' ')} - #{command.help}"
        end

        def description
          command.help_long
        end

        def examples
          command.examples
        end

        def exit_rows
          []
        end

        def ending
          nil
        end
      end
    end
    private_constant(:Profiles)
  end
end
