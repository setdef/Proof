# frozen_string_literal: true

module Proof
  module CommandLine
    class Spec
      # steep:ignore:start
      class Example < Data.define(:node)
        # steep:ignore:end
        def code
          node.text("code").to_s
        end

        def header
          node.text("header")
        end

        def help
          node.text("help")
        end
      end
    end
  end
end
