# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
    # steep:ignore:start
    class FlagSlot < Data.define(:item)
      # steep:ignore:end
      def entry(values)
        [member, values.public_send(reader, item.name)]
      end

      private def member
        item.name.tr("-", "_").to_sym
      end

      private def reader
        return :flag? unless item.takes_value?

        item.repeatable? ? :list : :text
      end
    end
    private_constant(:FlagSlot)
  end
end
