# frozen_string_literal: true

require_relative("test_helper")
require "openssl"

# Architecture, "Certificates": the server makes an EC P-256 key with Ruby's `openssl`, and the command and every runner
# pin the SHA-256 of its public key, in the form Git's `http.pinnedPubkey` takes.
class ServerIdentityTest < Minitest::Test
  # A key made for this test with `openssl ecparam -name prime256v1 -genkey`. It guards nothing.
  KEY = <<~PEM
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgF9Zz+0uxRZ2PmxIB
    vOZndw+2sSFp+fvpHle1FKP5eKOhRANCAAQP+QYjREjspyCwSLT1PErdufgjfrJk
    5Lbv0wwqcTBXYQUeJfOwkKYM9U/yezC76JSGW66Te2eaKx/ypt3C2foU
    -----END PRIVATE KEY-----
  PEM
  # The pin of KEY, from `openssl pkey -pubout -outform der | openssl dgst -sha256 -binary | base64`.
  PIN = "sha256//RPowkr56dtnxhFUAQhIN2qSkzIpKaWHT+C95kiPZAGY="
  private_constant(:KEY, :PIN)

  def test_the_fingerprint_is_the_pin_git_takes
    identity = Proof::Server::Identity.make(OpenSSL::PKey.read(KEY))

    assert_equal(PIN, identity.fingerprint)
  end

  def test_a_new_key_is_an_ec_p256_private_key
    key = Proof::Server::Identity.new_key

    assert_equal(["prime256v1", true], [key.group.curve_name, key.private?])
  end

  def test_the_certificate_is_signed_by_its_own_key
    key = Proof::Server::Identity.new_key
    certificate = Proof::Server::Identity.make(key).certificate

    assert(certificate.verify(key))
    assert_equal(certificate.subject, certificate.issuer)
    assert_equal("/CN=Proof server", certificate.subject.to_s)
  end

  # The pin is the trust, so the certificate carries the key and never expires.
  def test_the_certificate_starts_now_and_never_expires
    now = Time.utc(2026, 11, 26, 12, 0, 0)
    certificate = Proof::Server::Identity.make(Proof::Server::Identity.new_key, now:).certificate

    assert_equal([now, Time.utc(9999, 12, 31, 23, 59, 59)], [certificate.not_before, certificate.not_after])
  end

  def test_the_certificate_is_a_version_3_certificate
    assert_equal(2, Proof::Server::Identity.make(Proof::Server::Identity.new_key).certificate.version)
  end

  def test_the_certificate_is_for_a_tls_server_and_is_no_authority
    certificate = Proof::Server::Identity.make(Proof::Server::Identity.new_key).certificate
    extensions = certificate.extensions.to_h { |extension| [extension.oid, [extension.value, extension.critical?]] }

    assert_equal(["CA:FALSE", true], extensions["basicConstraints"])
    assert_equal(["Digital Signature", true], extensions["keyUsage"])
    assert_equal(["TLS Web Server Authentication", false], extensions["extendedKeyUsage"])
  end

  def test_each_certificate_has_a_positive_serial_of_at_most_20_octets
    serials = Array.new(20) { Proof::Server::Identity.make(Proof::Server::Identity.new_key).certificate.serial }

    assert(serials.all? { |serial| !serial.negative? && !serial.zero? && serial.num_bytes <= 20 })
    assert_equal(20, serials.uniq.size)
  end

  def test_a_key_that_isnt_ec_p256_is_refused
    keys = [OpenSSL::PKey::RSA.generate(2048), OpenSSL::PKey::EC.generate("secp384r1")]
    keys.each do |key|
      certificate = Proof::Server::Identity.make(OpenSSL::PKey.read(KEY)).certificate

      error = assert_raises(Proof::Server::IdentityError) { Proof::Server::Identity.new(key:, certificate:) }
      assert_equal("the server's key is an EC P-256 private key, not #{key.class}", error.message)
    end
  end

  def test_a_public_key_alone_is_refused
    public_key = OpenSSL::PKey.read(OpenSSL::PKey.read(KEY).public_to_pem)
    certificate = Proof::Server::Identity.make(OpenSSL::PKey.read(KEY)).certificate

    assert_raises(Proof::Server::IdentityError) { Proof::Server::Identity.new(key: public_key, certificate:) }
  end

  def test_a_certificate_for_another_key_is_refused
    certificate = Proof::Server::Identity.make(Proof::Server::Identity.new_key).certificate

    error = assert_raises(Proof::Server::IdentityError) do
      Proof::Server::Identity.new(key: OpenSSL::PKey.read(KEY), certificate:)
    end
    assert_equal("the certificate is for another key", error.message)
  end
end
