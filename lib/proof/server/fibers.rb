# frozen_string_literal: true

require "async"

module Proof
  module Server
    class Fibers
      CHECK_EVERY = 1
      public_constant(:CHECK_EVERY)

      def initialize(https:, watch:, stop:)
        @https = https
        @watch = watch
        @stop = stop
      end

      def serve
        Sync { |task| serve_in(task) }
      ensure
        @https.close
      end

      private def serve_in(task)
        serving = @https.start
        watching = task.async { watch_every_second }
        @stop.wait
        [serving, watching].each(&:stop)
      end

      private def watch_every_second
        loop do
          # Kernel#sleep yields to the fiber scheduler, so the check waits without holding up a request.
          sleep(CHECK_EVERY)
          @watch.check
        end
      end
    end
  end
end
