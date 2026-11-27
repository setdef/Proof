# frozen_string_literal: true

require_relative("test_helper")
require "openssl"

# Architecture, "Certificates": "The server sends the runner its token encrypted to `R`", with ECDH, HKDF, and AES-GCM
# from Ruby's `openssl`, so "a relayed join request gets the attacker nothing it can read".
class RunnerKeyTest < Minitest::Test
  # The token every test here encrypts.
  TOKEN = "runner token"
  private_constant(:TOKEN)

  # A token encrypted to a new runner key, with that key.
  def encrypted
    runner = Proof::RunnerKey.generate
    [runner, Proof::RunnerKey.read(runner.public_der).encrypt(TOKEN)]
  end

  # The token encrypted, with one of its fields replaced by what the block gives for it.
  def changed(field)
    runner, token = encrypted
    [runner, token.with(field => yield(token.public_send(field)))]
  end

  # The bytes with the first one's lowest bit flipped.
  def flipped(bytes)
    bytes.dup.tap { |copy| copy.setbyte(0, copy.getbyte(0) ^ 1) }
  end

  # The server reads the key a join request carried, encrypts the token to it, and the runner decrypts it.
  def test_a_token_encrypted_to_a_runners_key_decrypts_with_it
    runner, token = encrypted

    assert_equal(TOKEN, runner.decrypt(token))
    assert_equal(Encoding::UTF_8, runner.decrypt(token).encoding)
  end

  # Architecture, "Certificates": the token reaches nobody but the runner, so another key never decrypts it.
  def test_a_token_encrypted_to_one_key_wont_decrypt_with_another
    _, token = encrypted

    assert_raises(Proof::TokenDecryptionError) { Proof::RunnerKey.generate.decrypt(token) }
  end

  # AES-GCM checks what it decrypts, so a changed ciphertext, nonce, or tag never decrypts.
  def test_a_changed_ciphertext_nonce_or_tag_wont_decrypt
    %i[ciphertext nonce auth_tag].each do |field|
      runner, token = changed(field) { |bytes| flipped(bytes) }

      assert_raises(Proof::TokenDecryptionError, field.to_s) { runner.decrypt(token) }
    end
  end

  # The key the token was encrypted with goes into the key that decrypts it, so another key in its place, or bytes
  # that aren't a key, never decrypt.
  def test_a_changed_ephemeral_key_wont_decrypt
    [Proof::RunnerKey.generate.public_der, "not a key"].each do |replacement|
      runner, token = changed(:ephemeral_key) { replacement }

      assert_raises(Proof::TokenDecryptionError) { runner.decrypt(token) }
    end
  end

  # Architecture, "Certificates": one message for every cause. Ruby keeps the error a rescue raises over as the new
  # error's cause and prints it after the message, so a refusal keeps no cause that would tell one failure from another.
  def test_a_refusal_keeps_no_cause
    %i[ciphertext ephemeral_key].each do |field|
      runner, token = changed(field) { |bytes| flipped(bytes) }
      error = assert_raises(Proof::TokenDecryptionError, field.to_s) { runner.decrypt(token) }

      assert_equal(["the token doesn't decrypt with this runner's key", nil], [error.message, error.cause], field.to_s)
    end
  end

  # Ruby's openssl checks as few bytes of a tag as it is given, so a token whose tag is cut short is refused before
  # anything decrypts it.
  def test_a_token_with_a_short_tag_is_refused
    _, token = encrypted

    assert_raises(Proof::InvalidEncryptedTokenError) { token.with(auth_tag: token.auth_tag.byteslice(0, 4)) }
  end

  # Each encryption has a key and a nonce of its own, so two encryptions of one token share nothing an attacker could
  # compare.
  def test_each_encryption_differs
    runner = Proof::RunnerKey.generate
    first, second = Array.new(2) { runner.encrypt(TOKEN) }

    refute_equal(first.ephemeral_key, second.ephemeral_key)
    refute_equal(first.nonce, second.nonce)
    refute_equal(first.ciphertext, second.ciphertext)
  end

  # The server holds only a runner's public key, which encrypts and can't decrypt.
  def test_a_public_key_alone_cant_decrypt
    runner = Proof::RunnerKey.generate
    server_side = Proof::RunnerKey.read(runner.public_der)

    refute_predicate(server_side.key, :private?)
    assert_raises(Proof::RunnerKeyError) { server_side.decrypt(runner.encrypt(TOKEN)) }
  end

  # A runner's key is an EC P-256 key, as the server's is, given as the DER of its public key.
  def test_a_key_of_another_kind_is_refused
    p384 = OpenSSL::PKey::EC.generate("secp384r1").public_to_der
    rsa = OpenSSL::PKey::RSA.generate(1024).public_to_der

    [p384, rsa, "not a key", ""].each do |der|
      assert_raises(Proof::RunnerKeyError) { Proof::RunnerKey.read(der) }
    end
    assert_raises(Proof::RunnerKeyError) { Proof::RunnerKey.new(key: "a key") }
  end

  # The bytes a join request carries, and that the join tag and the server's tag are over, are the DER of the public
  # key, and read back as the same key.
  def test_the_public_der_reads_back_as_the_same_key
    runner = Proof::RunnerKey.generate

    assert_equal(runner.key.public_to_der, runner.public_der)
    assert_equal(runner.public_der, Proof::RunnerKey.read(runner.public_der).public_der)
  end
end
