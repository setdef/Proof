# frozen_string_literal: true

require_relative("identity_error")

module Proof
  module Server
    class IdentityRefusal
      PUT_BACK = [
        "Put back the key the server made. To have it make a new one, delete both %<key>s and %<certificate>s;",
        "every computer and runner that trusts the server then has to trust it again.",
      ].join(" ").freeze
      REMAKE = "Delete %<certificate>s, and the server makes a new one for its key when it starts."
      MESSAGES = {
        key_not_pem: "%<key>s isn't a private key in PEM. #{PUT_BACK}",
        key_of_another_kind: "%<key>s holds a key that isn't EC P-256. #{PUT_BACK}",
        lost_key: "%<certificate>s is there, but %<key>s, its key, isn't. #{PUT_BACK}",
        certificate_not_pem: "%<certificate>s isn't a certificate in PEM. #{REMAKE}",
        another_key: "%<certificate>s isn't the certificate of the key in %<key>s. #{REMAKE}",
      }.freeze
      private_constant(:PUT_BACK, :REMAKE, :MESSAGES)

      def initialize(key:, certificate:)
        @paths = { key:, certificate: }.freeze
      end

      def error(reason)
        IdentityError.new(format(MESSAGES[reason], **@paths))
      end
    end
  end
end
