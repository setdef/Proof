# frozen_string_literal: true

require "openssl"
require_relative("identity_error")

module Proof
  module Server
    class Identity < Data.define(:key, :certificate)
      CURVE = "prime256v1"
      NAME = "Proof server"
      NO_EXPIRY = Time.utc(9999, 12, 31, 23, 59, 59)
      EXTENSIONS = %w[
        basicConstraints=critical,CA:FALSE
        keyUsage=critical,digitalSignature
        extendedKeyUsage=serverAuth
        subjectKeyIdentifier=hash
      ].freeze
      public_constant(:CURVE, :NAME, :NO_EXPIRY)
      private_constant(:EXTENSIONS)

      def self.new_key
        OpenSSL::PKey::EC.generate(CURVE)
      end

      def self.server_key?(key)
        return false unless key.is_a?(OpenSSL::PKey::EC) && key.private?

        group = key.group or return false
        group.curve_name == CURVE
      end

      def self.make(key, now: Time.now)
        certificate = unsigned(key, now)
        certificate.sign(key, "SHA256")
        new(key:, certificate:)
      end

      def initialize(key:, certificate:)
        unless self.class.server_key?(key)
          raise(IdentityError, "the server's key is an EC P-256 private key, not #{key.class}")
        end
        raise(IdentityError, "the certificate is for another key") unless certificate.check_private_key(key)

        super
      end

      def fingerprint
        "sha256//#{[OpenSSL::Digest::SHA256.digest(key.public_to_der)].pack('m0')}"
      end

      private_class_method def self.unsigned(key, now)
        certificate = named(OpenSSL::X509::Certificate.new)
        certificate.public_key = key
        certificate.not_before = now
        # The command, the runners, and Git trust the key, never the dates, so the certificate never expires: RFC 5280,
        # 4.1.2.5, gives this notAfter to a certificate with no well-defined expiration date.
        certificate.not_after = NO_EXPIRY
        extended(certificate)
      end

      private_class_method def self.named(certificate)
        certificate.version = 2
        # 127 random bits with the top one set: a positive serial of at most 20 octets, as RFC 5280 asks.
        certificate.serial = OpenSSL::BN.rand(127, 0)
        certificate.subject = certificate.issuer = OpenSSL::X509::Name.new([["CN", NAME]])
        certificate
      end

      private_class_method def self.extended(certificate)
        factory = OpenSSL::X509::ExtensionFactory.new
        factory.subject_certificate = factory.issuer_certificate = certificate
        EXTENSIONS.each { |extension| certificate.add_extension(factory.create_ext_from_string(extension)) }
        certificate
      end

      # @dynamic key, certificate
    end
  end
end
