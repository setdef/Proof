# frozen_string_literal: true

require_relative("test_helper")
require "tmpdir"

# Issue 64 and architecture, "Certificates": two servers that start at once never each write a key, because every
# computer and runner that trusts the server knows it by its key. The one that loses the race to write a file reads the
# file that won, and starts with the same identity.
class ServerIdentityFilesRaceTest < Minitest::Test
  def setup
    @folder = File.join(Dir.mktmpdir, "data", "proof", "server")
    @files = Proof::Server::IdentityFiles.new(folder: @folder)
    @other = Proof::Server::IdentityFiles.new(folder: @folder)
  end

  def teardown
    FileUtils.remove_entry(File.expand_path("../../..", @folder))
  end

  def test_a_server_that_loses_the_race_to_write_the_key_starts_with_the_key_that_won
    winners = before_writing(:new_key)

    assert_equal(@files.load_or_make.fingerprint, winners.first.fingerprint)
    assert_equal(winners.first.key.private_to_pem, File.read(@files.key_path))
  end

  def test_a_server_that_loses_the_race_to_write_the_certificate_starts_with_the_certificate_that_won
    @files.load_or_make
    File.delete(@files.certificate_path)
    winners = before_writing(:made_from)

    assert_equal(@files.load_or_make.certificate.to_pem, winners.first.certificate.to_pem)
  end

  def test_a_lost_race_leaves_no_other_file
    before_writing(:new_key)
    @files.load_or_make

    assert_equal(%w[certificate.pem key.pem], Dir.children(@folder).sort)
  end

  # A name that reads as no file and can't be linked to would make the server try for ever.
  def test_a_name_that_is_taken_and_reads_as_no_file_stops_the_start_instead_of_looping
    FileUtils.mkdir_p(@folder)
    File.symlink(File.join(@folder, "nowhere"), @files.key_path)

    assert_raises(Errno::EEXIST) { @files.load_or_make }
  end

  def test_every_folder_the_server_makes_is_the_accounts_alone
    @files.load_or_make

    folders = [@folder, File.dirname(@folder, 2), File.dirname(@folder, 3)]
    modes = folders.map { |folder| File.stat(folder).mode & 0o777 }

    assert_equal([0o700] * 3, modes)
  end

  # Has another server that starts at the same moment finish just before @files writes its +file+, and gives what that
  # server found, once the write is made.
  private def before_writing(file)
    winners = []
    other = @other
    @files.define_singleton_method(file) do |*arguments|
      winners << other.load_or_make if winners.empty?
      super(*arguments)
    end
    winners
  end
end
