# frozen_string_literal: true

require_relative("identity")
require_relative("identity_reader")
require_relative("kept_file")

module Proof
  module Server
    class IdentityFiles
      KEY = "key.pem"
      CERTIFICATE = "certificate.pem"
      ATTEMPTS = 2
      public_constant(:KEY, :CERTIFICATE)
      private_constant(:ATTEMPTS)

      attr_reader :key_path, :certificate_path

      def initialize(folder:)
        # The class line is ignored by Steep, which doesn't count attr_reader as defining the readers that the signature
        # declares.
        @key_path = File.join(folder, KEY)
        @certificate_path = File.join(folder, CERTIFICATE)
        @reader = IdentityReader.new(key_path: @key_path, certificate_path: @certificate_path)
      end

      def load_or_make
        # A second server that starts at the same moment can write a file between this server's read and its write. The
        # write then fails, and the file that won is the one to read: the key's, and then the certificate's.
        attempts = 0
        begin
          read_or_make
        rescue Errno::EEXIST
          attempts += 1
          retry if attempts <= ATTEMPTS

          raise
        end
      end

      private def read_or_make
        key_text = KeptFile.read(@key_path)
        key = key_text && @reader.key(key_text)
        certificate_text = KeptFile.read(@certificate_path) or return made_from(key || new_key)
        @reader.identity(key, @reader.certificate(certificate_text))
      end

      private def new_key
        Identity.new_key.tap { |key| KeptFile.write(@key_path, key.private_to_pem, mode: 0o600) }
      end

      private def made_from(key)
        Identity.make(key).tap do |identity|
          KeptFile.write(@certificate_path, identity.certificate.to_pem, mode: 0o644)
        end
      end

      # @dynamic key_path, certificate_path
    end
  end
end
