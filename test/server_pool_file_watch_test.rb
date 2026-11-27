# frozen_string_literal: true

require_relative("test_helper")
require "stringio"
require "tmpdir"

# Pool file reference: "The server reads the file again whenever it changes, so a change takes effect for the next run
# without a restart", and when the file has a mistake the server keeps the last version that had none. The server says
# what it read and why it kept an older version, on standard error, where its service's log keeps it.
class ServerPoolFileWatchTest < Minitest::Test
  GOOD = "server port=8443\n"
  CHANGED = "server port=9443\n"
  BAD = "server port=9443\nlimits output=\"400G\"\n"
  private_constant(:GOOD, :CHANGED, :BAD)

  def setup
    @folder = Dir.mktmpdir
    @path = File.join(@folder, "pool.kdl")
    @current = Proof::Server::CurrentPoolFile.new(path: @path)
    @err = StringIO.new
    @watch = Proof::Server::PoolFileWatch.new(current: @current, err: @err)
  end

  def teardown
    FileUtils.remove_entry(@folder)
  end

  def test_the_first_check_reads_the_file_and_says_so
    File.write(@path, GOOD)
    @watch.check

    assert_equal(8443, @current.port)
    assert_equal("proof: read #{@path}, and the next run uses it.\n", @err.string)
  end

  def test_a_change_is_read_on_the_next_check_without_a_restart
    File.write(@path, GOOD)
    @watch.check
    File.write(@path, CHANGED)
    @watch.check

    assert_equal(9443, @current.pool_file&.port&.number)
  end

  def test_a_file_that_hasnt_changed_isnt_read_again_or_reported_again
    File.write(@path, GOOD)
    @watch.check
    @err.truncate(0)
    @watch.check

    assert_empty(@err.string)
  end

  def test_a_mistake_after_a_good_version_keeps_it
    File.write(@path, GOOD)
    @watch.check
    File.write(@path, BAD)
    @watch.check

    assert_equal(8443, @current.port)
  end

  def test_a_mistake_is_reported_with_its_line_and_that_the_last_good_version_is_kept
    File.write(@path, GOOD)
    @watch.check
    @err = StringIO.new
    File.write(@path, BAD)
    Proof::Server::PoolFileWatch.new(current: @current, err: @err).check

    assert_equal(<<~TEXT, @err.string)
      proof: #{@path}:2: #{@current.mistake&.reason}
      proof: the server keeps the last version of #{@path} that had no mistake until you fix it.
    TEXT
  end

  def test_a_mistake_at_the_start_is_reported_and_the_server_runs_no_runs
    File.write(@path, BAD)
    @watch.check

    assert_nil(@current.pool_file)
    assert_equal(<<~TEXT, @err.string)
      proof: #{@path}:2: #{@current.mistake&.reason}
      proof: the server runs no runs until you fix #{@path}.
    TEXT
  end

  def test_a_fix_is_read_and_reported
    File.write(@path, BAD)
    @watch.check
    File.write(@path, GOOD)
    @watch.check

    assert_nil(@current.mistake)
    assert(@err.string.end_with?("proof: read #{@path}, and the next run uses it.\n"))
  end

  def test_a_missing_file_is_a_mistake_and_is_reported_once
    @watch.check
    @watch.check

    assert_equal(<<~TEXT, @err.string)
      proof: #{@path}: the server can't read it: No such file or directory
      proof: the server runs no runs until you fix #{@path}.
    TEXT
  end

  def test_a_file_put_back_after_it_was_missing_is_read
    File.write(@path, GOOD)
    @watch.check
    File.delete(@path)
    @watch.check
    File.write(@path, GOOD)
    @watch.check

    assert_nil(@current.mistake)
  end
end
