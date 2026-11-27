# frozen_string_literal: true

require "async"
require "net/http"
require "openssl"
require "socket"

# What the tests of the server's HTTPS share: a client that trusts the server only by the fingerprint of its key, as the
# command and the runners will, and a server run in a thread of its own until the test is done with it.
module ServerHttpsClient
  # What a request got back: the TLS protocol of its connection, and the body of the answer.
  Answer = Struct.new(:protocol, :body)
  private_constant(:Answer)

  # Sends GET +path+ to 127.0.0.1 at +port+, over a connection that goes on only when the server's key has
  # +fingerprint+.
  def request(port, path, fingerprint:, max_version: OpenSSL::SSL::TLS1_3_VERSION)
    http = Net::HTTP.new("127.0.0.1", port)
    http.use_ssl = true
    http.max_version = max_version
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    # The server's certificate names no host, and the fingerprint is the whole of the trust.
    http.verify_hostname = false
    http.verify_callback = -> (_, store) { fingerprint_of(store.current_cert) == fingerprint }
    http.start { |started| Answer.new(protocol(port, fingerprint), started.get(path).body) }
  end

  # The TLS protocol a new connection to +port+ agrees on.
  def protocol(port, fingerprint)
    context = OpenSSL::SSL::SSLContext.new
    context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    context.verify_callback = -> (_, store) { fingerprint_of(store.current_cert) == fingerprint }
    socket = OpenSSL::SSL::SSLSocket.new(TCPSocket.new("127.0.0.1", port), context)
    socket.sync_close = true
    socket.connect
    socket.ssl_version
  ensure
    socket&.close
  end

  # The pin of +certificate+'s key, in the form of Git's http.pinnedPubkey.
  def fingerprint_of(certificate)
    "sha256//#{[OpenSSL::Digest::SHA256.digest(certificate.public_key.public_to_der)].pack('m0')}"
  end

  # Runs +server+, which answers +start+ with a task, in a thread with a fiber scheduler, gives the block +port+, and
  # stops the server when the block returns. Returns what the block returns.
  def in_server_thread(server, port)
    reader, writer = IO.pipe
    thread = server_thread(server, reader)
    yield(port)
  ensure
    writer&.write(".")
    thread&.join
    [reader, writer].each { |io| io&.close }
  end

  # A thread that runs +server+ until +reader+ can be read, returned once the server listens.
  def server_thread(server, reader)
    ready = Thread::Queue.new
    thread = Thread.new { Sync { serve_until(server, reader, ready) } }
    ready.pop
    thread
  end

  # Runs +server+ in the current fiber scheduler, says so on +ready+, and stops it once +reader+ can be read.
  def serve_until(server, reader, ready)
    serving = server.start
    ready << true
    reader.wait_readable
    serving.stop
  end
end
