# frozen_string_literal: true

require "socket"

module Proof
  module Server
    class Root
      def self.requests
        Requests.new({ "/version" => { "GET" => VersionRequest.new } })
      end

      def initialize(home:, err:, host: nil)
        @paths = Paths.under(home)
        @err = err
        @host = host
        @stop = Stop.new
      end

      def serve
        current = CurrentPoolFile.new(path: @paths.pool_file)
        watch = PoolFileWatch.new(current:, err: @err).tap(&:check)
        Fibers.new(https: https_for(current), watch:, stop: @stop).serve
        @err.write("proof: stopped.\n")
      end

      def stop
        @stop.ask
      end

      private def https_for(current)
        identity = IdentityFiles.new(folder: @paths.folder).load_or_make
        port = current.port
        sockets = listen(port)
        @err.write("proof: listening on port #{port}, with the fingerprint #{identity.fingerprint}.\n")
        Https.new(app: Root.requests, identity:, sockets:, err: @err)
      end

      private def listen(port)
        Socket.tcp_server_sockets(@host, port)
      rescue SystemCallError => e
        raise(ListenError, "the server can't listen on port #{port}: #{SystemCallError.new(e.errno).message}")
      end
    end
  end
end
