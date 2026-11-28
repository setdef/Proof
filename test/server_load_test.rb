# frozen_string_literal: true

require_relative("loaded_gems")
require_relative("test_helper")

# Architecture, "The HTTP server": Falcon and the gems it loads wait until the server serves HTTPS, so the command, which
# never does, starts on Ruby's standard library alone. Architecture, "Where the server keeps its state": `etcetera`,
# which finds the server's folders, waits until the server names them.
class ServerLoadTest < Minitest::Test
  include LoadedGems

  # Falcon and the gems it loads when the server serves HTTPS, and `etcetera` when the server finds its folders.
  SERVER_GEMS = %w[
    etcetera
    falcon
    async
    async-http
    async-http-cache
    async-utilization
    console
    fiber-annotation
    fiber-local
    fiber-storage
    io-endpoint
    io-event
    io-stream
    protocol-hpack
    protocol-http
    protocol-http1
    protocol-http2
    protocol-rack
    rack
  ].freeze
  REQUIRE_PROOF = <<~RUBY
    before = $LOADED_FEATURES.dup
    require("proof")
    puts($LOADED_FEATURES - before)
  RUBY
  NAME_HTTPS = <<~RUBY
    before = $LOADED_FEATURES.dup
    require("proof")
    Proof::Server::Https
    puts($LOADED_FEATURES - before)
  RUBY
  NAME_PATHS = <<~RUBY
    before = $LOADED_FEATURES.dup
    require("proof")
    Proof::Server::Paths
    puts($LOADED_FEATURES - before)
  RUBY
  private_constant(:SERVER_GEMS, :REQUIRE_PROOF, :NAME_HTTPS, :NAME_PATHS)

  def test_requiring_proof_loads_no_server_gem
    assert_empty(gems_in(loaded_by(REQUIRE_PROOF), SERVER_GEMS))
  end

  # Naming the server's HTTPS loads Falcon, and works on a process that hasn't loaded it before.
  def test_naming_the_servers_https_loads_falcon
    loaded = gems_in(loaded_by(NAME_HTTPS), SERVER_GEMS)

    assert_equal(%w[async falcon protocol-rack], loaded.intersection(%w[falcon async protocol-rack]).sort)
  end

  # Naming the server's paths loads `etcetera`, and works on a process that hasn't loaded it before.
  def test_naming_the_servers_paths_loads_etcetera
    assert_equal(%w[etcetera], gems_in(loaded_by(NAME_PATHS), SERVER_GEMS).sort)
  end
end
