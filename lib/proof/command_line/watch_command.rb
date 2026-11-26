# frozen_string_literal: true

module Proof
  module CommandLine
    # steep:ignore:start
    class WatchCommand < Data.define(:run, :json)
      # steep:ignore:end
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
    end
  end
end
