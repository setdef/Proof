# frozen_string_literal: true

require_relative("server_https_client")
require_relative("test_helper")
require "socket"
require "stringio"
require "timeout"

# Architecture, "The HTTP server" and "Certificates": the server is Falcon, which serves each connection on a fiber, over
# TLS 1.3 only, with the server's own key. Every wait in the server has to yield, because a handler that blocks without
# yielding stalls every request.
class ServerHttpsTest < Minitest::Test
  include ServerHttpsClient

  # Answers every request with its path.
  APP = lambda do |env|
    [200, { "content-type" => "text/plain" }, [env["PATH_INFO"].to_s]]
  end
  # Seconds after which a request that should have been answered is taken to hang. It is far longer than any request
  # takes, so it never decides a pass.
  HANG_GUARD = 30
  private_constant(:APP, :HANG_GUARD)

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

  # The slow request is held open by a latch until the fast one has been answered, so the order of the answers decides
  # the test, and no limit on seconds does. A server that handles one request at a time never answers the fast request
  # while it holds the slow one, so the fast request waits out +HANG_GUARD+ and fails. The guard only ends a hang, and
  # a pass never waits for it.
  def test_a_slow_request_doesnt_stall_another
    entered = Thread::Queue.new
    release = Thread::Queue.new
    serving(held_until(entered, release)) do |port|
      slow = Thread.new { request(port, "/slow", fingerprint: @identity.fingerprint) }
      fast = fast_request_while_held(port, entered, release)

      assert_equal(["/fast", "/slow"], [fast.body, slow.value.body])
    end
  end

  def test_a_stopped_server_answers_no_more
    port = serving { |listening| listening }

    assert_raises(Errno::ECONNREFUSED) { TCPSocket.new("127.0.0.1", port) }
  end

  # The answer to a request for /fast, made once the handler holds /slow. The handler is let go when this returns or
  # fails, so a server that stalls the fast request ends with the guard's error and not with a hang.
  private def fast_request_while_held(port, entered, release)
    assert(entered.pop(timeout: HANG_GUARD), "the slow request never reached the server's handler")
    Timeout.timeout(HANG_GUARD) { request(port, "/fast", fingerprint: @identity.fingerprint) }
  ensure
    release << :go
  end

  # An application that answers every request with its path, and holds /slow, after it pushes to +entered+, until
  # +release+ has something. Queue#pop yields to the fiber scheduler, as a wait in the server has to.
  private def held_until(entered, release)
    lambda do |env|
      path = env["PATH_INFO"].to_s
      if path == "/slow"
        entered << :in
        release.pop
      end
      [200, { "content-type" => "text/plain" }, [path]]
    end
  end

  # Serves +app+ on a port the system picks, on 127.0.0.1, until the block returns, and gives the block the port.
  private def serving(app = APP, &)
    sockets = Socket.tcp_server_sockets("127.0.0.1", 0)
    https = Proof::Server::Https.new(app:, identity: @identity, sockets:, err: @err)
    in_server_thread(https, sockets.first.local_address.ip_port, &)
  ensure
    sockets&.each(&:close)
  end
end
