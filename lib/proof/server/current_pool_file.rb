# frozen_string_literal: true

module Proof
  module Server
    class CurrentPoolFile
      attr_reader :path, :pool_file, :mistake

      def initialize(path:)
        # The class line is ignored by Steep, which doesn't count attr_reader as defining the readers that the signature
        # declares.
        @path = path
        @reader = PoolFileReader.new(path:)
        @pool_file = nil
        @mistake = nil
      end

      def read(text)
        # The reader builds the whole file before it returns any of it, so a mistake on any line leaves the last good
        # version in use.
        @pool_file = @reader.read(text)
        @mistake = nil
      rescue PoolFileError => e
        @mistake = e
      end

      def unreadable(reason)
        @mistake = PoolFileError.new(path: @path, line: nil, reason: "the server can't read it: #{reason}")
      end

      def port
        (@pool_file || PoolFile.new).port.number
      end

      # @dynamic path, pool_file, mistake
    end
  end
end
