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
      end
    end
  end
end
