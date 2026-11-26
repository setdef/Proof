# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks the settings that a host's entry, or the pool file's `defaults` node, gives, and how they combine.
class HostSettingsTest < Minitest::Test
  include PoolFileHelper

  MESSAGES = {
    budget: "a host's budget is a size, not \"x\"",
    keep_free: "a host's keep-free space is a size, not \"x\"",
    share: "a host's share is resources, not \"x\"",
    active_for: "a host's active-for time is a duration, not \"x\"",
    withheld: "a host's withheld labels are a set of labels, not \"x\"",
  }.freeze
  private_constant(:MESSAGES)

  # Pool file reference, "`host`", table: each child that a host's entry gives is kept as given: `budget`, `keep-free`,
  # `share`, `active-for`, and `withhold`.
  def test_each_setting_is_kept_as_given
    settings = host_settings(
      budget: "250GB", keep_free: "50 GiB", share: [4, "16GB"], active_for: "10m", withhold: %w[gpu]
    )

    assert_equal(
      [size("250GB"), size("50GiB"), share_of(4, "16GB"), duration("10m"), Proof::LabelSet.of("gpu")],
      [settings.budget, settings.keep_free, settings.share, settings.active_for, settings.withheld]
    )
  end

  # Pool file reference, "`host`": an entry may give none of these, and "`defaults`" "takes the same children as a
  # `host`", so settings that give nothing are what a file with no such child has.
  def test_settings_that_are_not_given_are_nothing
    settings = Proof::HostSettings.new

    assert_equal(
      [nil] * 5, [settings.budget, settings.keep_free, settings.share, settings.active_for, settings.withheld]
    )
  end

  # Pool file reference, "`host`", `share`: "With a share of `cpus=0 memory="0GB"`, Proof keeps nothing free ... Proof
  # accepts it", so a share of no CPUs and no memory is a setting.
  def test_a_share_of_nothing_is_accepted
    assert_equal(Proof::Resources.new(cpus: 0, megabytes: 0), host_settings(share: [0, "0GB"]).share)
  end

  # Pool file reference, "`host`": a `budget` "can run to terabytes", and a size of 0 keeps nothing, so a budget and
  # a space to keep free of 0 are sizes.
  def test_a_size_of_zero_is_accepted
    settings = host_settings(budget: "0GB", keep_free: "0GB")

    assert_equal([size("0GB")] * 2, [settings.budget, settings.keep_free])
  end

  # Pool file reference, "`defaults`": "The settings every `host` gets unless its entry has a different value", so a
  # host's own value beats the defaults' value, and the defaults fill in what the host lacks.
  def test_a_value_in_the_entry_beats_the_defaults
    entry = host_settings(budget: "250GB", share: [4, "16GB"])
    defaults = host_settings(budget: "100GB", share: [2, "4GB"], active_for: "5m")
    merged = entry.over(defaults)

    assert_equal([size("250GB"), share_of(4, "16GB"), duration("5m")], [merged.budget, merged.share, merged.active_for])
  end

  # The same sentence: a host's share replaces the defaults' share as a whole, so a host that gives `cpus=4` and a
  # memory has no CPUs or memory from the defaults.
  def test_a_share_is_replaced_as_a_whole
    merged = host_settings(share: [4, "16GB"]).over(host_settings(share: [2, "4GB"]))

    assert_equal(share_of(4, "16GB"), merged.share)
  end

  # Project file reference, "How values combine": lists such as `label` "add", and the glossary says labels add up from
  # every source, so the labels that a host withholds add to the labels that `defaults` withholds.
  def test_withheld_labels_add
    merged = host_settings(withhold: %w[gpu]).over(host_settings(withhold: %w[desktop gpu]))

    assert_equal(Proof::LabelSet.of("gpu", "desktop"), merged.withheld)
  end

  # Pool file reference, "`host`", `withhold`: the default is "None", so settings with no withheld labels over
  # settings with none are none.
  def test_nothing_withheld_over_nothing_withheld_is_nothing
    assert_nil(Proof::HostSettings.new.over(Proof::HostSettings.new).withheld)
  end

  # Labels withheld on one side only are all that is withheld.
  def test_labels_withheld_on_one_side_are_kept
    assert_equal(Proof::LabelSet.of("gpu"), host_settings(withhold: %w[gpu]).over(Proof::HostSettings.new).withheld)
    assert_equal(Proof::LabelSet.of("gpu"), Proof::HostSettings.new.over(host_settings(withhold: %w[gpu])).withheld)
  end

  # What a source gives that the other lacks is kept, in either order, so a value is never lost by combining.
  def test_a_setting_that_only_one_side_gives_is_kept
    assert_equal(size("400GB"), host_settings(budget: "400GB").over(Proof::HostSettings.new).budget)
    assert_equal(size("400GB"), Proof::HostSettings.new.over(host_settings(budget: "400GB")).budget)
  end

  # Pool file reference, "Sizes and labels": a size, a share, a duration, or a label set of the wrong kind is a
  # mistake in the file, so settings built from another kind of value are refused.
  def test_a_setting_of_the_wrong_kind_is_refused
    [{ budget: "400GB" }, { keep_free: 25 }, { share: 4 }, { active_for: "5m" }, { withheld: ["gpu"] }].each do |given|
      assert_raises(Proof::InvalidHostSettingsError, given.inspect) { Proof::HostSettings.new(**given) }
    end
  end

  # The message names the setting and what it got.
  def test_the_message_names_the_setting
    MESSAGES.each do |member, message|
      error = assert_raises(Proof::InvalidHostSettingsError) { Proof::HostSettings.new(member => "x") }

      assert_equal(message, error.message)
    end
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidHostSettingsError, :<, Proof::Error)
  end
end
