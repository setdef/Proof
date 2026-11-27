# frozen_string_literal: true

require_relative("test_helper")
require "tmpdir"

# The server's key is written once and never replaced, because every computer and runner that trusts the server knows
# it by that key. Proof::Server::KeptFile holds that rule for every file the server keeps so.
class ServerKeptFileTest < Minitest::Test
  def setup
    @folder = Dir.mktmpdir
    @path = File.join(@folder, "new", "key.pem")
  end

  def teardown
    FileUtils.remove_entry(@folder)
  end

  def test_a_file_that_isnt_there_reads_as_nothing
    assert_nil(Proof::Server::KeptFile.read(@path))
  end

  def test_a_written_file_reads_as_its_text
    Proof::Server::KeptFile.write(@path, "the key\n", mode: 0o600)

    assert_equal("the key\n", Proof::Server::KeptFile.read(@path))
  end

  def test_the_file_has_its_mode_and_its_new_folder_is_the_accounts_alone
    Proof::Server::KeptFile.write(@path, "the key\n", mode: 0o600)

    assert_equal([0o600, 0o700], [File.stat(@path).mode & 0o777, File.stat(File.dirname(@path)).mode & 0o777])
  end

  def test_a_file_that_is_there_is_never_replaced
    Proof::Server::KeptFile.write(@path, "the first key\n", mode: 0o600)

    assert_raises(Errno::EEXIST) { Proof::Server::KeptFile.write(@path, "a second key\n", mode: 0o600) }
    assert_equal("the first key\n", File.read(@path))
  end

  def test_a_refused_write_leaves_no_other_file
    Proof::Server::KeptFile.write(@path, "the first key\n", mode: 0o600)
    assert_raises(Errno::EEXIST) { Proof::Server::KeptFile.write(@path, "a second key\n", mode: 0o600) }

    assert_equal(["key.pem"], Dir.children(File.dirname(@path)))
  end
end
