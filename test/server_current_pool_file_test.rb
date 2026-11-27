# frozen_string_literal: true

require_relative("test_helper")

# Pool file reference, "What happens when the file has a mistake": the server checks the whole file before it uses any
# of it, keeps running with the last version that had none, and shows the mistake, with its line, until it is fixed. A
# server that starts with a mistake runs no runs until it is fixed.
class ServerCurrentPoolFileTest < Minitest::Test
  PATH = "/home/proof/.config/proof/pool.kdl"
  GOOD = "server port=8443\nhost nuc {\n  runner nuc-linux\n  budget \"400GB\"\n}\n"
  # A good port on line 1, and a mistake on line 2.
  BAD = "server port=9443\nlimits output=\"400G\"\n"
  private_constant(:PATH, :GOOD, :BAD)

  def setup
    @current = Proof::Server::CurrentPoolFile.new(path: PATH)
  end

  def test_before_any_reading_there_is_no_pool_file_and_no_mistake
    assert_nil(@current.pool_file)
    assert_nil(@current.mistake)
  end

  def test_a_good_file_is_the_one_in_use
    @current.read(GOOD)

    assert_equal(["nuc"], @current.pool_file&.hosts&.map(&:name))
    assert_nil(@current.mistake)
  end

  def test_a_file_with_a_mistake_is_held_as_the_mistake_with_its_path_and_line
    @current.read(BAD)

    assert_equal([PATH, 2], [@current.mistake&.path, @current.mistake&.line])
  end

  def test_a_server_that_starts_with_a_mistake_has_no_pool_file_to_run_runs_with
    @current.read(BAD)

    assert_nil(@current.pool_file)
  end

  def test_a_mistake_keeps_the_last_version_that_had_none
    @current.read(GOOD)
    good = @current.pool_file
    @current.read(BAD)

    assert_same(good, @current.pool_file)
  end

  # The port on the line before the mistake is never used, because none of a file with a mistake is.
  def test_no_part_of_a_file_with_a_mistake_is_used
    @current.read(GOOD)
    @current.read(BAD)

    assert_equal(8443, @current.port)
  end

  def test_a_fix_clears_the_mistake_and_is_the_one_in_use
    @current.read(BAD)
    @current.read(GOOD)

    assert_nil(@current.mistake)
    assert_equal(8443, @current.pool_file&.port&.number)
  end

  def test_a_file_that_cant_be_read_is_a_mistake_with_no_line
    @current.read(GOOD)
    @current.unreadable("No such file or directory")

    assert_equal("#{PATH}: the server can't read it: No such file or directory", @current.mistake&.message)
    assert_nil(@current.mistake&.line)
    assert_equal(8443, @current.port)
  end

  def test_the_port_is_the_pool_file_page_default_with_no_good_version
    @current.read(BAD)

    assert_equal(7443, @current.port)
  end
end
