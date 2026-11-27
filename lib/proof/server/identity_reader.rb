# frozen_string_literal: true

require "openssl"
require_relative("identity")
require_relative("identity_refusal")

module Proof
  module Server
    class IdentityReader
      def initialize(key_path:, certificate_path:)
        @refusal = IdentityRefusal.new(key: key_path, certificate: certificate_path)
      end

      def key(text)
        key = OpenSSL::PKey.read(text)
        return key if key.is_a?(OpenSSL::PKey::EC) && Identity.server_key?(key)

        raise(@refusal.error(:key_of_another_kind))
      rescue OpenSSL::PKey::PKeyError
        raise(@refusal.error(:key_not_pem))
      end

      def certificate(text)
        OpenSSL::X509::Certificate.new(text)
      rescue OpenSSL::X509::CertificateError
        raise(@refusal.error(:certificate_not_pem))
      end

      def identity(key, certificate)
        raise(@refusal.error(:lost_key)) unless key
        raise(@refusal.error(:another_key)) unless certificate.check_private_key(key)

        Identity.new(key:, certificate:)
      end
    end
  end
end
