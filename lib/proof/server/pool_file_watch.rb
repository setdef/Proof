# frozen_string_literal: true

module Proof
  module Server
    class PoolFileWatch
      def initialize(current:, err:)
        @current = current
        @err = err
        @checked = false
        @seen = nil
      end

      def check
        text = File.read(@current.path)
      rescue SystemCallError => e
        # The error's own message names the call and the path, which the mistake already gives.
        seen(nil) { @current.unreadable(SystemCallError.new(e.errno).message) }
      else
        seen(text) { @current.read(text) }
      end

      private def seen(text)
        return if @checked && text == @seen

        @checked = true
        @seen = text
        yield
        report
      end

      private def report
        path = @current.path
        mistake = @current.mistake or return say("read #{path}, and the next run uses it.")

        say(mistake.message)
        return say("the server runs no runs until you fix #{path}.") unless @current.pool_file

        say("the server keeps the last version of #{path} that had no mistake until you fix it.")
      end

      private def say(line)
        @err.write("proof: #{line}\n")
      end
    end
  end
end
