# frozen_string_literal: true

require "json"

module Proof
  module Server
    class Requests
      def self.json(status, value, headers = {})
        [status, { "content-type" => "application/json", **headers }, [JSON.generate(value)]]
      end

      def self.refused(path, method, allowed)
        json(405, { error: "#{path} takes #{allowed}, not #{method}" }, { "allow" => allowed })
      end

      def initialize(routes)
        @routes = routes
      end

      def call(env)
        method = env["REQUEST_METHOD"].to_s
        path = env["PATH_INFO"].to_s
        request = @routes.dig(path, method) or return refusal(path, method)
        request.call(env)
      end

      private def refusal(path, method)
        methods = @routes[path] or return Requests.json(404, { error: "the server has no request at #{path}" })
        Requests.refused(path, method, methods.keys.join(", "))
      end
    end
  end
end
