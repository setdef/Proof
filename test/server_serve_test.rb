# frozen_string_literal: true

require_relative("test_helper")
require "open3"
require "rbconfig"
require "socket"
require "stringio"
require "tmpdir"

# Issue 64: the server process is started by an entry point that the service `proof server setup` makes will run. A
# service manager stops it with TERM, and a person at a terminal with Ctrl-C, which sends INT. It exits 0 when it was
# stopped and 1 when it couldn't start, with the reason on standard error.
class ServerServeTest < Minitest::Test
  LIB = File.expand_path("../lib", __dir__)
  private_constant(:LIB)

  def setup
    @home = Dir.mktmpdir
    @port = free_port
    write(File.join(@home, ".config", "proof", "pool.kdl"), "server port=#{@port}\n")
    @err = StringIO.new
  end

  def teardown
    FileUtils.remove_entry(@home)
  end

  def test_term_stops_the_server_and_it_exits_with_zero
    assert_equal(0, serve_until_signal("TERM"))
    assert(@err.string.end_with?("proof: stopped.\n"))
  end

  def test_int_stops_the_server_and_it_exits_with_zero
    assert_equal(0, serve_until_signal("INT"))
  end

  # The server's signal handlers last only as long as it serves, so code that called it keeps its own.
  def test_the_handlers_from_before_are_back_once_it_returns
    before = proc {}
    previous = Signal.trap("TERM", before)
    serve_until_signal("TERM")

    assert_same(before, Signal.trap("TERM", previous))
  end

  def test_a_key_the_server_cant_use_stops_it_from_starting_with_status_one
    write(File.join(@home, ".local", "share", "proof", "server", "key.pem"), "not a key\n")

    assert_equal(1, Proof::Server.serve(home: @home, err: @err, host: "127.0.0.1"))
    assert_match(%r{\Aproof: .*/key\.pem isn't a private key in PEM\.}, @err.string.lines.last)
  end

  def test_a_folder_the_server_cant_make_stops_it_from_starting_with_status_one
    write(File.join(@home, ".local", "share"), "a file where the folder goes\n")

    assert_equal(1, Proof::Server.serve(home: @home, err: @err, host: "127.0.0.1"))
    assert_match(/\Aproof: the server can't start: /, @err.string.lines.last)
  end

  def test_a_port_another_program_holds_stops_it_from_starting_with_status_one
    holder = TCPServer.new("127.0.0.1", @port)

    assert_equal(1, Proof::Server.serve(home: @home, err: @err, host: "127.0.0.1"))
    assert_match(/\Aproof: the server can't listen on port #{@port}: /, @err.string.lines.last)
  ensure
    holder&.close
  end

  # A fresh Ruby process with Proof's lib folder on its load path starts the server, as the service will.
  def test_a_new_process_serves_until_term_and_exits_with_zero
    code = 'require("proof"); exit(Proof::Server.serve(host: "127.0.0.1"))'
    Open3.popen3({ "HOME" => @home }, RbConfig.ruby, "-I", LIB, "-e", code) do |_, _, err, waiter|
      assert_includes(err.gets.to_s, "proof: read ")
      assert_includes(err.gets.to_s, "proof: listening on port #{@port}")
      Process.kill("TERM", waiter.pid)

      assert_equal([0, "proof: stopped.\n"], [waiter.value.exitstatus, err.read])
    end
  end

  # Serves in a thread until it says it listens, sends this process +signal+, and returns the exit status. The server
  # says it listens only after it has its handlers, so the signal never reaches a process with none.
  private def serve_until_signal(signal)
    thread = Thread.new { Proof::Server.serve(home: @home, err: @err, host: "127.0.0.1") }
    sleep(0.05) until @err.string.include?("proof: listening on port") || !thread.alive?
    Process.kill(signal, Process.pid) if thread.alive?
    thread.value
  end

  private def write(path, text)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, text)
  end

  # A port the system picked, free when this returns.
  private def free_port
    server = TCPServer.new("127.0.0.1", 0)
    server.addr[1]
  ensure
    server&.close
  end
end
