# frozen_string_literal: true

module Proof
  module CommandLine
    # steep:ignore:start
    class RunnerSetupCommand < Data.define(:server, :name, :desktop, :no_wsl, :dry_run)
      # steep:ignore:end
    end
  end
end
