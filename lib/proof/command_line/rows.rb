# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    module Rows
      # steep:ignore:end
      # steep:ignore:start
      class FlagRow < Data.define(:item)
        # steep:ignore:end
        def label
          value = (" <#{item.value}>" if item.takes_value?)
          "#{item.switches.join(', ')}#{value}"
        end

        def text
          choices = item.choices
          "#{item.help}#{" (#{item.strict? ? 'one of' : 'such as'} #{choices.join(', ')})" unless choices.empty?}"
        end
      end

      # steep:ignore:start
      class ArgRow < Data.define(:item)
        # steep:ignore:end
        def label
          item.to_s
        end

        def text
          item.help.to_s
        end
      end

      # steep:ignore:start
      class CommandRow < Data.define(:item)
        # steep:ignore:end
        def label
          item.name
        end

        def text
          item.help.to_s
        end
      end

      # steep:ignore:start
      class ExitRow < Data.define(:item)
        # steep:ignore:end
        def label
          item.status.to_s
        end

        def text
          item.help
        end
      end
    end
    private_constant(:Rows)
  end
end
