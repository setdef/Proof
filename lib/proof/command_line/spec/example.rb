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

        # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      end
    end
  end
end
