# frozen_string_literal: true

module Proof
  module CommandLine
    # steep:ignore:start
    class LogsCommand < Data.define(:run, :tail, :no_pager)
      # steep:ignore:end
    end
  end
end
