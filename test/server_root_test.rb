# frozen_string_literal: true

require_relative("server_https_client")
require_relative("test_helper")
require_relative("xdg_environment")
require "json"
require "socket"
require "stringio"
require "tmpdir"

# Issue 64: the server makes its key and certificate on its first start and keeps them, serves HTTPS on the pool file's
# port, reads the pool file again when it changes, and answers the server's version. It keeps its state in
# ~/.local/share/proof/server and reads the pool file from ~/.config/proof/pool.kdl, as architecture.md says. Issue 131:
# `XDG_DATA_HOME` and `XDG_CONFIG_HOME` move them.
class ServerRootTest < Minitest::Test
  include ServerHttpsClient
  include XdgEnvironment

  def setup
    @home = Dir.mktmpdir
    @pool_file = File.join(@home, ".config", "proof", "pool.kdl")
    FileUtils.mkdir_p(File.dirname(@pool_file))
    @port = free_port
    File.write(@pool_file, "server port=#{@port}\n")
    @err = StringIO.new
  end

  def teardown
    FileUtils.remove_entry(@home)
  end

  def test_the_server_answers_its_version_on_the_pool_files_port
    body = serving { request(@port, "/version", fingerprint:).body }

    assert_equal({ "version" => Proof::VERSION }, JSON.parse(body))
  end

  def test_the_server_keeps_its_key_and_certificate_in_its_folder
    serving { nil }

    assert_equal(%w[certificate.pem key.pem], Dir.children(File.join(@home, ".local", "share", "proof", "server")).sort)
  end

  def test_the_server_keeps_its_key_and_certificate_in_xdg_data_home_and_reads_the_pool_file_in_xdg_config_home
    config = File.join(@home, "elsewhere", "config", "proof", "pool.kdl")
    FileUtils.mkdir_p(File.dirname(config))
    File.write(config, "server port=#{@port}\n")
    data = File.join(@home, "elsewhere", "data")

    with_xdg(data:, config: File.join(@home, "elsewhere", "config")) { serving { nil } }

    assert_equal(%w[certificate.pem key.pem], Dir.children(File.join(data, "proof", "server")).sort)
    assert_includes(@err.string, "proof: read #{config},")
  end

  # A client that trusted the server's key on its first start still trusts it on the next.
  def test_the_server_keeps_its_key_from_one_start_to_the_next
    serving { nil }
    first = fingerprint
    body = serving { request(@port, "/version", fingerprint: first).body }

    assert_equal({ "version" => Proof::VERSION }, JSON.parse(body))
  end

  def test_the_server_says_where_it_listens_and_the_fingerprint_it_is_known_by
    serving { nil }

    assert_includes(@err.string, "proof: listening on port #{@port}, with the fingerprint #{fingerprint}.\n")
  end

  def test_the_server_reads_the_pool_file_when_it_starts
    serving { nil }

    assert(@err.string.start_with?("proof: read #{@pool_file}, and the next run uses it.\n"))
  end

  def test_a_change_to_the_pool_file_is_read_while_the_server_serves
    serving do
      File.write(@pool_file, "server port=#{@port}\nretention runs=\"30d\"\n")

      read_again = within_five_seconds? { @err.string.scan("proof: read #{@pool_file}").size == 2 }

      assert(read_again, "standard error: #{@err.string}")
    end
  end

  def test_a_mistake_in_the_pool_file_while_the_server_serves_is_reported_and_the_server_goes_on
    serving do
      File.write(@pool_file, "server port=#{@port}\nlimits output=\"400G\"\n")

      kept = within_five_seconds? { @err.string.include?("that had no mistake until you fix it.") }

      assert(kept, "standard error: #{@err.string}")
      assert_equal({ "version" => Proof::VERSION }, JSON.parse(request(@port, "/version", fingerprint:).body))
    end
  end

  def test_a_stopped_server_says_so_and_answers_no_more
    serving { nil }

    assert(@err.string.end_with?("proof: stopped.\n"))
    assert_raises(Errno::ECONNREFUSED) { TCPSocket.new("127.0.0.1", @port) }
  end

  # The fingerprint of the key in the server's folder.
  private def fingerprint
    folder = File.join(@home, ".local", "share", "proof", "server")
    Proof::Server::IdentityFiles.new(folder:).load_or_make.fingerprint
  end

  # A port the system picked, free when this returns.
  private def free_port
    server = TCPServer.new("127.0.0.1", 0)
    server.addr[1]
  ensure
    server&.close
  end

  # Serves on 127.0.0.1 until the block returns, and returns what the block returns.
  private def serving
    root = Proof::Server::Root.new(home: @home, err: @err, host: "127.0.0.1")
    listening = @err.string.scan("proof: listening on port").size
    thread = Thread.new { root.serve }
    raise(@err.string) unless within_five_seconds? { @err.string.scan("proof: listening on port").size > listening }

    yield
  ensure
    root&.stop
    thread&.join
  end

  # Whether the block is true within 5 seconds.
  private def within_five_seconds?
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    until yield
      return false if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

      sleep(0.05)
    end
    true
  end
end
