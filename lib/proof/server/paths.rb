# frozen_string_literal: true

module Proof
  module Server
    # steep:ignore:start
    class Paths < Data.define(:pool_file, :folder)
      # steep:ignore:end
      POOL_FILE = ".config/proof/pool.kdl"
      FOLDER = ".local/share/proof/server"
      public_constant(:POOL_FILE, :FOLDER)

      def self.under(home)
        new(pool_file: File.join(home, POOL_FILE), folder: File.join(home, FOLDER))
      end
    end
  end
end
