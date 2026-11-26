# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
    # steep:ignore:start
    class ArgSlot < Data.define(:item)
      # steep:ignore:end
      def entry(values)
        [member, values.public_send(reader, item.name)]
      end

      private def member
        name = item.name
        item.repeatable? ? :"#{name}s" : name.to_sym
      end

      private def reader
        item.repeatable? ? :list : :first
      end
    end
    private_constant(:ArgSlot)
  end
end
