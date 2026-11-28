# frozen_string_literal: true

require "etcetera"

module Proof
  module Server
    class Paths < Data.define(:pool_file, :folder)
      POOL_FILE = "proof/pool.kdl"
      FOLDER = "proof/server"
      public_constant(:POOL_FILE, :FOLDER)

      def self.find(home)
        xdg = Etcetera::BaseStrategy::Xdg.new(home_dir: Pathname.new(home))
        new(pool_file: xdg.config_dir.join(POOL_FILE).to_s, folder: xdg.data_dir.join(FOLDER).to_s)
      end

      # @dynamic pool_file, folder, initialize
    end
  end
end
