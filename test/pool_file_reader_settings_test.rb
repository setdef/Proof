# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the size and the share of a host or of `defaults`: the wrong type, or a size that breaks its
# rule. Each is refused at the line of its child, with what the domain says.
class PoolFileReaderSettingsTest < Minitest::Test
  include PoolFileReaderHelper

  CPUS = [["\"four\"", "four"], ["1.5", 1.5], ["#null", nil], ["-1", -1]].freeze
  private_constant(:CPUS)

  # The text of `defaults` with this child on line 2.
  def defaults_with(child)
    "defaults {\n  #{child}\n}\n"
  end

  # The settings of `defaults` with this child.
  def settings_of(child)
    read(defaults_with(child)).defaults
  end

  # Pool file reference, "Sizes and labels", first table: each row marked valid is read as the megabytes it gives.
  def test_each_valid_size_in_the_page_table_is_read_into_megabytes
    megabytes = [
      settings_of("budget \"1.5TB\"").budget,
      settings_of("keep-free \"50 GiB\"").keep_free,
      settings_of("share cpus=2 memory=\"0.1GB\"").share,
    ].map(&:megabytes)

    assert_equal([1_572_864, 51_200, 103], megabytes)
  end

  # The same table: `budget "400G"` is "Refused: `G` isn't a unit", and `keep-free "25 GB "` is refused for its space.
  def test_each_refused_size_in_the_page_table_is_refused
    [["budget", "400G"], ["keep-free", "25 GB "]].each do |name, text|
      assert_refused(
        defaults_with("#{name} \"#{text}\""), 2, domain_said(Proof::InvalidSizeError) { Proof::Size.read(text, name:) }
      )
    end
  end

  # The same table: `budget 400GB` is "Refused: KDL reads `400GB` as the number 400 followed by `GB`", so the text is
  # refused as text that is not KDL, with the quotes that work.
  def test_an_unquoted_size_is_refused_with_the_way_to_quote_it
    assert_refused(
      defaults_with("budget 400GB"),
      2,
      "this is not valid KDL 2: unexpected IDENT \"GB\" at column 13. " \
        "If a value starts with a digit and continues with letters, put it in quotes, as in memory=\"8GB\""
    )
  end

  # Pool file reference, "`host`": `budget "SIZE"` and `keep-free "SIZE"` are quoted sizes, so a number is refused.
  def test_a_budget_or_a_keep_free_that_is_a_number_is_refused
    %w[budget keep-free].each do |name|
      assert_refused(
        defaults_with("#{name} 400"), 2, domain_said(Proof::InvalidSizeError) { Proof::Size.read(400, name:) }
      )
    end
  end

  # Pool file reference, "`host`": `share cpus=N memory="SIZE"`, so CPUs that are text, a decimal, `#null`, or negative
  # are refused, with what the domain says.
  def test_a_share_with_cpus_that_break_the_rule_is_refused
    CPUS.each do |written, cpus|
      assert_refused(
        defaults_with("share cpus=#{written} memory=\"4GB\""),
        2,
        domain_said(Proof::InvalidResourcesError) { Proof::Resources.new(cpus:, megabytes: 4096) }
      )
    end
  end

  # The same row: a memory that isn't a size is refused, with the share's memory named.
  def test_a_share_with_memory_that_is_not_a_size_is_refused
    assert_refused(
      defaults_with("share cpus=2 memory=\"4G\""),
      2,
      domain_said(Proof::InvalidSizeError) { Proof::Size.read("4G", name: "share memory") }
    )
  end

  # Pool file reference, "`host`", the warning: "With a share of `cpus=0 memory="0GB"`, Proof keeps nothing free ...
  # Proof accepts it."
  def test_a_share_of_nothing_is_accepted
    assert_equal(share_of(0, "0GB"), settings_of("share cpus=0 memory=\"0GB\"").share)
  end
end
