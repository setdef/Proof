# frozen_string_literal: true

require_relative("test_helper")
require "json"

# Server design, "Versions": the command checks the server's version on each call. The server answers each request by
# its method and path, and says when it has no such request.
class ServerRequestsTest < Minitest::Test
  def setup
    @requests = Proof::Server::Requests.new({ "/version" => { "GET" => Proof::Server::VersionRequest.new } })
  end

  def test_the_version_request_answers_the_server_version_as_json
    status, headers, body = @requests.call(env("GET", "/version"))

    assert_equal(200, status)
    assert_equal("application/json", headers["content-type"])
    assert_equal({ "version" => Proof::VERSION }, JSON.parse(body.join))
  end

  def test_a_version_given_to_the_request_is_the_one_it_answers
    _, _, body = Proof::Server::VersionRequest.new(version: "0.9.0").call(env("GET", "/version"))

    assert_equal('{"version":"0.9.0"}', body.join)
  end

  def test_a_path_the_server_has_no_request_at_is_not_found
    status, headers, body = @requests.call(env("GET", "/versions"))

    assert_equal([404, "application/json"], [status, headers["content-type"]])
    assert_equal({ "error" => "the server has no request at /versions" }, JSON.parse(body.join))
  end

  def test_a_method_the_path_doesnt_take_is_refused_with_the_methods_it_takes
    status, headers, body = @requests.call(env("POST", "/version"))

    assert_equal([405, "GET"], [status, headers["allow"]])
    assert_equal({ "error" => "/version takes GET, not POST" }, JSON.parse(body.join))
  end

  # A client can send any bytes in a path, and JSON holds only text, so the answer shows a byte that isn't UTF-8 as the
  # replacement character, where an exception would answer with a server error.
  def test_a_path_that_isnt_utf_8_is_not_found
    status, _, body = @requests.call(env("GET", "/\xFF".b))

    assert_equal(404, status)
    assert_equal({ "error" => "the server has no request at /\uFFFD" }, JSON.parse(body.join))
  end

  def test_a_method_that_isnt_utf_8_is_refused
    status, _, body = @requests.call(env("G\xFFT".b, "/version"))

    assert_equal(405, status)
    assert_equal({ "error" => "/version takes GET, not G\uFFFDT" }, JSON.parse(body.join))
  end

  private def env(method, path)
    { "REQUEST_METHOD" => method, "PATH_INFO" => path }
  end
end
