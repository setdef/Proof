# frozen_string_literal: true

module Proof
  module CommandLine
    # steep:ignore:start
    class DownloadCommand < Data.define(:run, :patterns, :output, :json)
      # steep:ignore:end
    end
  end
end
