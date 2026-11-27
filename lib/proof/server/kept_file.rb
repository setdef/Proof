# frozen_string_literal: true

require "fileutils"
require "securerandom"

module Proof
  module Server
    module KeptFile
      def self.read(path)
        File.read(path)
      rescue Errno::ENOENT
        nil
      end

      def self.write(path, text, mode:)
        temporary = "#{path}.#{SecureRandom.hex(8)}.tmp"
        begin
          write_new(temporary, text, mode)
          # Making a link fails when the name is taken, where a rename replaces the file, so a file is never replaced.
          File.link(temporary, path)
        ensure
          FileUtils.rm_f(temporary)
        end
      end

      private_class_method def self.write_new(path, text, mode)
        FileUtils.mkdir_p(File.dirname(path), mode: 0o700)
        File.open(path, File::WRONLY | File::CREAT | File::EXCL, mode) do |file|
          file.write(text)
          # The text reaches the disk before its name does, so a crash never leaves the name on an empty file.
          file.fsync
        end
      end
    end
  end
end
