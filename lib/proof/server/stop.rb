# frozen_string_literal: true

module Proof
  module Server
    class Stop
      def initialize
        @reader, @writer = IO.pipe
      end

      def ask
        # A signal handler can't take a lock, and a write that waited would block it, so the byte is written without
        # waiting. A pipe too full to take it already holds a stop to read.
        @writer.write_nonblock(".", exception: false)
      end

      def wait
        @reader.wait_readable
        nil
      end
    end
  end
end
