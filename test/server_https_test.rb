# frozen_string_literal: true

require_relative("server_https_client")
require_relative("test_helper")
require "socket"
require "stringio"

# Architecture, "The HTTP server" and "Certificates": the server is Falcon, which serves each connection on a fiber, over
# TLS 1.3 only, with the server's own key. Every wait in the server has to yield, because a handler that blocks without
# yielding stalls every request.
class ServerHttpsTest < Minitest::Test
  include ServerHttpsClient

  # Answers every request with its path, after a second for /slow. Kernel#sleep yields to the fiber scheduler.
  APP = lambda do |env|
    path = env["PATH_INFO"].to_s
    sleep(1) if path == "/slow"
    [200, { "content-type" => "text/plain" }, [path]]
  end
  private_constant(:APP)

  def setup
    @identity = Proof::Server::Identity.make(Proof::Server::Identity.new_key)
    @err = StringIO.new
  end

  def test_a_request_is_answered_over_tls_1_3_with_the_servers_key
    serving do |port|
      answer = request(port, "/version", fingerprint: @identity.fingerprint)

      assert_equal(["TLSv1.3", "/version"], [answer.protocol, answer.body])
    end
  end

  def test_a_client_that_trusts_another_key_never_sends_its_request
    other = Proof::Server::Identity.make(Proof::Server::Identity.new_key).fingerprint

    serving { |port| assert_raises(OpenSSL::SSL::SSLError) { request(port, "/version", fingerprint: other) } }
  end

  def test_a_client_that_offers_only_tls_1_2_is_refused_and_the_server_goes_on
    serving do |port|
      assert_raises(OpenSSL::SSL::SSLError) do
        request(port, "/version", fingerprint: @identity.fingerprint, max_version: OpenSSL::SSL::TLS1_2_VERSION)
      end
      assert_equal("/version", request(port, "/version", fingerprint: @identity.fingerprint).body)
    end
  end

  # A refused handshake is a client's mistake, which the server's log doesn't need.
  def test_a_refused_handshake_writes_nothing_to_standard_error
    serving do |port|
      assert_raises(OpenSSL::SSL::SSLError) do
        request(port, "/version", fingerprint: @identity.fingerprint, max_version: OpenSSL::SSL::TLS1_2_VERSION)
      end
    end

    assert_empty(@err.string)
  end

  def test_a_slow_request_doesnt_stall_another
    serving do |port|
      slow = Thread.new { request(port, "/slow", fingerprint: @identity.fingerprint) }
      sleep(0.1)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      request(port, "/fast", fingerprint: @identity.fingerprint)

      assert_operator(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 0.5)
      assert_predicate(slow, :alive?, "the slow request ended before the fast one, so the test shows nothing")
      assert_equal("/slow", slow.value.body)
    end
  end

  def test_a_stopped_server_answers_no_more
    port = serving { |listening| listening }

    assert_raises(Errno::ECONNREFUSED) { TCPSocket.new("127.0.0.1", port) }
  end

  # Serves APP on a port the system picks, on 127.0.0.1, until the block returns, and gives the block the port.
  private def serving(&)
    sockets = Socket.tcp_server_sockets("127.0.0.1", 0)
    https = Proof::Server::Https.new(app: APP, identity: @identity, sockets:, err: @err)
    in_server_thread(https, sockets.first.local_address.ip_port, &)
  ensure
    sockets&.each(&:close)
  end
end
