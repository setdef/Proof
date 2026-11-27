# frozen_string_literal: true

require "async/http/protocol/http11"
require "console"
require "falcon/server"
require "io/endpoint/bound_endpoint"
require "io/endpoint/ssl_endpoint"
require "openssl"

module Proof
  module Server
    class Https
      def self.context(identity)
        OpenSSL::SSL::SSLContext.new.tap do |context|
          context.min_version = OpenSSL::SSL::TLS1_3_VERSION
          context.max_version = OpenSSL::SSL::TLS1_3_VERSION
          context.add_certificate(identity.certificate, identity.key)
        end
      end

      def initialize(app:, identity:, sockets:, err:)
        bound = IO::Endpoint::BoundEndpoint.new(nil, sockets)
        @endpoint = IO::Endpoint::SSLEndpoint.new(bound, ssl_context: Https.context(identity))
        @middleware = Falcon::Server.rack_middleware(app, cache: false)
        @err = err
      end

      def run
        # Falcon logs a refused handshake as a warning, with its backtrace, and a scanner of ports would fill the
        # server's log with them. The logger is the fiber's, so the server's fibers alone log only errors.
        logger = Console::Config::DEFAULT.make_logger(@err)
        logger.level = :error
        Console.logger = logger
        Falcon::Server.new(@middleware, @endpoint, protocol: Async::HTTP::Protocol::HTTP11, scheme: "https").run
      end
    end
  end
end
