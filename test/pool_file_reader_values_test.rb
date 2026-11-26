# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the duration, the labels, and the names of a host or of `defaults`: the wrong type, or a
# value that breaks its rule. Each is refused at the line of its node, with what the domain says.
class PoolFileReaderValuesTest < Minitest::Test
  include PoolFileReaderHelper

  ACTIVE_FOR = ["1h30m", "5 m", "5M", "1d"].freeze
  LABELS = ["nvidia gpu", "gpu-", ""].freeze
  private_constant(:ACTIVE_FOR, :LABELS)

  # The text of `defaults` with this child on line 2.
  def defaults_with(child)
    "defaults {\n  #{child}\n}\n"
  end

  # Pool file reference, "Durations": `active-for "5m"` is "Valid", and a duration in seconds is a duration too.
  def test_the_page_rows_that_give_an_active_for_are_read
    durations = %w[5m 90s].map { |text| read(defaults_with("active-for \"#{text}\"")).defaults.active_for }

    assert_equal([duration("5m"), duration("90s")], durations)
  end

  # The same table: each `active-for` row marked refused is refused, with what the domain says of the written value.
  def test_each_refused_active_for_in_the_page_table_is_refused
    ACTIVE_FOR.each do |text|
      assert_refused(
        defaults_with("active-for \"#{text}\""),
        2,
        domain_said(Proof::InvalidDurationError) { Proof::Duration.read(text, units: %i[s m h], name: "active-for") }
      )
    end
  end

  # Pool file reference, "`host`": `active-for "DURATION"` is quoted, so a number and `#null` are refused.
  def test_an_active_for_that_is_not_text_is_refused
    [["5", 5], ["#null", nil]].each do |written, value|
      assert_refused(
        defaults_with("active-for #{written}"),
        2,
        domain_said(Proof::InvalidDurationError) { Proof::Duration.read(value, units: %i[s m h], name: "active-for") }
      )
    end
  end

  # Pool file reference, "Sizes and labels", second table: `withhold gpu desktop` is valid, and `withhold GPU` is
  # "Valid, and the same as `withhold gpu`".
  def test_each_valid_label_row_is_read
    labels = ["gpu desktop", "GPU", "gpu"].map { |text| read(defaults_with("withhold #{text}")).defaults.withheld }

    assert_equal([Proof::LabelSet.of("gpu", "desktop"), labels.last, labels.last], [labels.first, *labels.drop(1)])
  end

  # The same table: `withhold "nvidia gpu"` and `withhold gpu-` are refused, and so is a label that is empty.
  def test_each_refused_label_row_is_refused
    LABELS.each do |name|
      assert_refused(
        defaults_with("withhold \"#{name}\""), 2, domain_said(Proof::InvalidLabelError) { Proof::Label.new(name:) }
      )
    end
  end

  # A label that is a number is refused, as the project file's reader refuses one, with what the domain says.
  def test_a_label_that_is_not_text_is_refused
    assert_refused(defaults_with("withhold 4"), 2, domain_said(Proof::InvalidLabelError) { Proof::Label.new(name: 4) })
  end

  # A host whose name is not text is refused at the host's line, with what the domain says.
  def test_a_host_name_that_is_not_text_is_refused
    assert_refused(
      "host 5 {\n  runner a\n}\n",
      1,
      domain_said(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: 5, runners: %w[a]) }
    )
  end

  # A runner that is not text, or listed twice on one host, is refused at the host's line, with what the domain says.
  def test_a_runner_that_is_not_text_or_is_listed_twice_is_refused
    assert_refused(
      "host a {\n  runner 5\n}\n",
      1,
      domain_said(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: "a", runners: [5]) }
    )
    assert_refused(
      "host a {\n  runner r\n  runner r\n  budget \"1GB\"\n}\n",
      1,
      domain_said(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: "a", runners: %w[r r]) }
    )
  end
end
