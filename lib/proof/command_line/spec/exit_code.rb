# frozen_string_literal: true

module Proof
  module CommandLine
    class Spec
      # steep:ignore:start
      class ExitCode < Data.define(:node)
        # steep:ignore:end
        def status
          node.whole_number("code")
        end

        def help
          node.text("help").to_s
        end

        # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      end
    end
  end
end
