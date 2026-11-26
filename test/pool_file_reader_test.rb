# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks that the reader of the pool file builds what the pool file page says each form means.
class PoolFileReaderTest < Minitest::Test
  include PoolFileReaderHelper

  # Pool file reference, "`server`": `port` has the default `7443`, so a file with no `server` node has it, and a file
  # with nothing has every default.
  def test_an_empty_file_has_the_defaults
    assert_equal(Proof::PoolFile.new, read(""))
  end

  # A file of comments has no nodes, so it has the defaults too.
  def test_a_file_of_comments_has_the_defaults
    assert_equal(Proof::PoolFile.new, read("// Proof's pool\n/* none yet */\n"))
  end

  # Pool file reference, "`server`": `server port=7443`, "The TCP port the server listens on".
  def test_the_server_has_its_port
    ports = %w[7443 8443 1 65535].map { |port| read("server port=#{port}\n").port }

    assert_equal([7443, 8443, 1, 65_535], ports.map(&:number))
  end

  # The same row: a `server` node with no `port` leaves the default.
  def test_a_server_node_with_no_port_has_the_default_port
    assert_equal(7443, read("server\n").port.number)
  end

  # Pool file reference, "A complete example": `server`, `retention`, and `limits` are three nodes of one file, each of
  # which sets its own part of the pool file.
  def test_the_server_retention_and_limits_nodes_set_their_own_parts
    file = read("server port=8443\nretention output=\"30d\"\nlimits artifacts=\"2GB\"\n")

    assert_equal(
      [
        Proof::Port.new(number: 8443),
        Proof::Retention.new(output: days("30d")),
        Proof::Limits.new(artifacts: size("2GB")),
      ],
      [file.port, file.retention, file.limits]
    )
  end

  # Pool file reference, "`retention`": `retention runs="90d" output="14d" artifacts="7d"`.
  def test_retention_has_its_three_durations
    retention = read("retention runs=\"60d\" output=\"3d\" artifacts=\"2d\"\n").retention

    assert_equal(Proof::Retention.new(runs: days("60d"), output: days("3d"), artifacts: days("2d")), retention)
  end

  # Pool file reference, "Examples", "Keep runs' output longer": `retention output="30d"`, where "The `runs` and
  # `artifacts` values keep their defaults."
  def test_the_page_example_that_keeps_output_longer
    retention = read(page_example("### Keep runs' output longer")).retention

    assert_equal(Proof::Retention.new(runs: days("90d"), output: days("30d"), artifacts: days("7d")), retention)
  end

  # Pool file reference, "`retention`": a file with no `retention` node has the defaults in its table.
  def test_a_file_with_no_retention_has_the_default_retention
    assert_equal(Proof::Retention.new, read("server port=7443\n").retention)
  end

  # Pool file reference, "`limits`": `limits output="1GB" artifacts="16GB"`.
  def test_limits_have_their_two_sizes
    assert_equal(
      Proof::Limits.new(output: size("2GB"), artifacts: size("32GB")),
      read("limits output=\"2GB\" artifacts=\"32GB\"\n").limits
    )
  end

  # The same table: a limit that is not given keeps its default, and a file with no `limits` node has both.
  def test_a_limit_that_is_not_given_keeps_its_default
    assert_equal(Proof::Limits.new(output: size("512mb")), read("limits output=\"512mb\"\n").limits)
    assert_equal(Proof::Limits.new, read("").limits)
  end
end
