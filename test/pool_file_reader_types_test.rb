# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in a value: the wrong type, or a port, a size, or a duration that breaks its rule.
class PoolFileReaderTypesTest < Minitest::Test
  include PoolFileReaderHelper

  PORTS = [
    ["\"7443\"", "7443"], ["1.5", 1.5], ["#null", nil], ["0", 0], ["65536", 65_536], ["-1", -1], ["#true", true]
  ].freeze
  DURATIONS = %w[runs output artifacts].freeze
  SIZES = %w[output artifacts].freeze
  private_constant(:PORTS, :DURATIONS, :SIZES)

  # Project file reference, "Mistakes Proof catches", which the pool file reference points to: "a value has the wrong
  # type". Pool file reference, "`server`": `port` is "A port number", so a port that is text, a decimal, `#null`, a
  # boolean, or outside 1 to 65535 is refused at its node's line, with what the domain says of it.
  def test_a_port_that_is_not_a_port_number_is_refused
    PORTS.each do |written, value|
      assert_refused(
        "// the server\nserver port=#{written}\n",
        2,
        domain_said(Proof::InvalidPoolFileError) { Proof::PoolFile.new(port: value) }
      )
    end
  end

  # Pool file reference, "`retention`": "Each value is a quoted duration in days", so a number, a duration with no
  # unit, and a duration in minutes are refused, whichever value they are in, with the setting's name.
  def test_a_retention_value_that_is_not_a_duration_in_days_is_refused
    [["90", 90], ["\"90\"", "90"], ["\"90m\"", "90m"], ["#null", nil]].each do |written, value|
      DURATIONS.each do |name|
        assert_refused(
          "retention #{name}=#{written}\n",
          1,
          domain_said(Proof::InvalidDurationError) { days_named(value, "retention #{name}") }
        )
      end
    end
  end

  # Pool file reference, "`limits`": each value is a size, so a number, a unit that isn't one, and `#null` are refused,
  # with the setting's name.
  def test_a_limit_that_is_not_a_size_is_refused
    [["400", 400], ["\"400G\"", "400G"], ["#null", nil]].each do |written, value|
      SIZES.each do |name|
        assert_refused(
          "limits #{name}=#{written}\n",
          1,
          domain_said(Proof::InvalidSizeError) { Proof::Size.read(value, name: "limits #{name}") }
        )
      end
    end
  end

  # Pool file reference, "Durations": `retention output="14h"` is "Refused: `retention` takes days."
  def test_the_page_row_that_gives_retention_hours_is_refused
    assert_refused(
      "retention output=\"14h\"\n",
      1,
      domain_said(Proof::InvalidDurationError) { days_named("14h", "retention output") }
    )
  end

  # The wrong form is refused at the line of its node, so a mistake on a later line is named there.
  def test_a_mistake_is_refused_at_the_line_of_its_node
    assert_refused(
      "server port=7443\n\n\nlimits output=\"400G\"\n",
      4,
      domain_said(Proof::InvalidSizeError) { Proof::Size.read("400G", name: "limits output") }
    )
  end
end
