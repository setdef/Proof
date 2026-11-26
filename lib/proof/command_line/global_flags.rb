# frozen_string_literal: true

module Proof
  module CommandLine
    # steep:ignore:start
    class GlobalFlags < Data.define(:quiet, :debug, :no_color, :no_input)
      # steep:ignore:end
    end
  end
end
