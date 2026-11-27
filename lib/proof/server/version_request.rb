# frozen_string_literal: true

require_relative("requests")

module Proof
  module Server
    class VersionRequest
      def initialize(version: VERSION)
        @version = version
      end

      def call(_env)
        Requests.json(200, { version: @version })
      end
    end
  end
end
