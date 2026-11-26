# frozen_string_literal: true

module Proof
  module CommandLine
    class Spec
      # steep:ignore:start
      class Group < Data.define(:node)
        # steep:ignore:end
        def names
          node.texts("members")
        end

        def required?
          node.true?("required")
        end
      end
    end
  end
end
