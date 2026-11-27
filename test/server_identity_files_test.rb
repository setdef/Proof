# frozen_string_literal: true

require_relative("test_helper")
require "openssl"
require "tmpdir"

# Issue 64 and architecture, "Certificates": the server makes its key and certificate on its first start and keeps them,
# because every computer and runner that trusts it knows it by its key, and nothing re-pins by itself after a key
# change. So it never makes a key while a certificate is there, and never replaces a file it finds.
class ServerIdentityFilesTest < Minitest::Test
  def setup
    @home = Dir.mktmpdir
    @folder = File.join(@home, "data", "proof", "server")
    @files = Proof::Server::IdentityFiles.new(folder: @folder)
    @key_path = @files.key_path
    @certificate_path = @files.certificate_path
  end

  def teardown
    FileUtils.remove_entry(@home)
  end

  def test_the_files_are_in_the_folder
    assert_equal([File.join(@folder, "key.pem"), File.join(@folder, "certificate.pem")], [@key_path, @certificate_path])
  end

  def test_the_first_start_makes_the_folder_the_key_and_the_certificate
    identity = @files.load_or_make

    assert_equal(identity.key.private_to_pem, File.read(@key_path))
    assert_equal(identity.certificate.to_pem, File.read(@certificate_path))
  end

  def test_only_the_account_can_read_the_key_or_open_the_folder
    @files.load_or_make

    assert_equal(0o600, File.stat(@key_path).mode & 0o777)
    assert_equal(0o644, File.stat(@certificate_path).mode & 0o777)
    assert_equal(0o700, File.stat(@folder).mode & 0o777)
  end

  def test_the_files_are_kept_and_read_again_on_the_next_start
    first = @files.load_or_make
    again = Proof::Server::IdentityFiles.new(folder: @folder).load_or_make

    assert_equal(first.fingerprint, again.fingerprint)
    assert_equal(first.certificate.to_der, again.certificate.to_der)
  end

  def test_making_them_leaves_no_other_file
    @files.load_or_make

    assert_equal(%w[certificate.pem key.pem], Dir.children(@folder).sort)
  end

  def test_a_certificate_is_made_again_for_the_key_that_is_there
    key = @files.load_or_make.key
    File.delete(@certificate_path)
    again = @files.load_or_make

    assert_equal(key.private_to_pem, again.key.private_to_pem)
    assert_equal(key.private_to_pem, File.read(@key_path))
    assert_equal(again.certificate.to_pem, File.read(@certificate_path))
  end

  def test_a_certificate_without_its_key_is_refused_and_no_key_is_made
    @files.load_or_make
    File.delete(@key_path)

    error = assert_raises(Proof::Server::IdentityError) { @files.load_or_make }
    assert_equal(
      "#{@certificate_path} is there, but #{@key_path}, its key, isn't. Put back the key the server made. " \
        "To have it make a new one, delete both #{@key_path} and #{@certificate_path}; every computer and runner " \
        "that trusts the server then has to trust it again.",
      error.message
    )
    refute_path_exists(@key_path)
  end

  def test_a_key_that_isnt_pem_is_refused
    write(@key_path, "not a key\n")

    error = assert_raises(Proof::Server::IdentityError) { @files.load_or_make }
    assert_match(/\A#{Regexp.escape(@key_path)} isn't a private key in PEM\. Put back the key/, error.message)
    assert_equal("not a key\n", File.read(@key_path))
  end

  def test_a_key_that_isnt_ec_p256_is_refused
    write(@key_path, OpenSSL::PKey::RSA.generate(2048).private_to_pem)

    error = assert_raises(Proof::Server::IdentityError) { @files.load_or_make }
    assert_match(/\A#{Regexp.escape(@key_path)} holds a key that isn't EC P-256\. Put back the key/, error.message)
  end

  def test_a_certificate_that_isnt_pem_is_refused
    @files.load_or_make
    write(@certificate_path, "not a certificate\n")

    error = assert_raises(Proof::Server::IdentityError) { @files.load_or_make }
    assert_equal(
      "#{@certificate_path} isn't a certificate in PEM. Delete #{@certificate_path}, and the server " \
        "makes a new one for its key when it starts.",
      error.message
    )
  end

  def test_a_certificate_of_another_key_is_refused_and_kept
    @files.load_or_make
    other = Proof::Server::Identity.make(Proof::Server::Identity.new_key).certificate.to_pem
    write(@certificate_path, other)

    error = assert_raises(Proof::Server::IdentityError) { @files.load_or_make }
    assert_equal(
      "#{@certificate_path} isn't the certificate of the key in #{@key_path}. Delete " \
        "#{@certificate_path}, and the server makes a new one for its key when it starts.",
      error.message
    )
    assert_equal(other, File.read(@certificate_path))
  end

  private def write(path, text)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end
end
