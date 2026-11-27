# frozen_string_literal: true

module Proof
  module Server
    class Service
      SIGNALS = %w[INT TERM].freeze
      public_constant(:SIGNALS)

      def self.reason(error)
        # Proof's own errors say what to do; an error from the system says only what failed.
        message = error.message
        error.is_a?(Error) ? message : "the server can't start: #{message}"
      end

      def initialize(home:, err:, host: nil)
        @root = Root.new(home:, err:, host:)
        @err = err
      end

      def serve
        as_the_process { @root.serve }
        0
      rescue Error, SystemCallError => e
        failed(e)
      end

      private def as_the_process
        # The fiber scheduler reads and writes through IO::Buffer, and Ruby warns once that IO::Buffer is experimental,
        # which nobody who reads the server's log can act on. The server process is Proof's, so the switch is too.
        Warning[:experimental] = false
        previous = trap_signals
        begin
          yield
        ensure
          previous.each { |signal, handler| Signal.trap(signal, handler) }
        end
      end

      private def trap_signals
        SIGNALS.to_h { |signal| [signal, Signal.trap(signal) { @root.stop }] }
      end

      private def failed(error)
        @err.write("proof: #{Service.reason(error)}\n")
        1
      end
    end
  end
end
