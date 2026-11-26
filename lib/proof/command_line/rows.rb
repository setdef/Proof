# frozen_string_literal: true

module Proof
  module CommandLine
    module Rows
      class FlagRow
        def initialize(item)
          @item = item
        end

        def label
          value = (" <#{@item.value}>" if @item.takes_value?)
          "#{@item.switches.join(', ')}#{value}"
        end

        def text
          choices = @item.choices
          "#{@item.help}#{" (#{@item.strict? ? 'one of' : 'such as'} #{choices.join(', ')})" unless choices.empty?}"
        end
      end

      class ArgRow
        def initialize(item)
          @item = item
        end

        def label
          @item.to_s
        end

        def text
          @item.help.to_s
        end
      end

      class CommandRow
        def initialize(item)
          @item = item
        end

        def label
          @item.name
        end

        def text
          @item.help.to_s
        end
      end

      class ExitRow
        def initialize(item)
          @item = item
        end

        def label
          @item.status.to_s
        end

        def text
          @item.help
        end
      end
    end
  end
end
