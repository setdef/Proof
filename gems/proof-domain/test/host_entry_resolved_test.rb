# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks the settings a host gets from its entry, then `defaults`, then Proof's built-in defaults.
class HostEntryResolvedTest < Minitest::Test
  include PoolFileHelper

  # The settings of a resolved host as a hash, as the page's tables list them.
  def settings_of(host)
    {
      budget: host.budget.megabytes,
      keep_free: host.keep_free.megabytes,
      share: host.share.to_h,
      active_for: host.active_for.seconds,
      withheld: host.withheld.labels.map(&:to_s),
    }
  end

  # Pool file reference, "A complete example": `nuc` has a budget of 400 GB from its entry, and the share of 2 CPUs and
  # 4 GB and the 5 minutes from `defaults`, and `keep-free` from the built-in defaults, `"25GB"`.
  def test_nuc_gets_its_budget_and_the_defaults
    host = nuc_entry.resolved(example_defaults)

    assert_equal(
      { budget: 409_600, keep_free: 25_600, share: { cpus: 2, megabytes: 4096 }, active_for: 300, withheld: [] },
      settings_of(host)
    )
  end

  # The same example: `pc` has its own budget of 250 GB, its own share of 4 CPUs and 16 GB, and `withhold gpu`, and the
  # rest from `defaults` and the built-in defaults. The page says "On `pc`, Proof may use 250 GB, keeps 16 GB of memory
  # free always and 4 CPUs free while someone is active there, and never offers the PC's GPU to a task."
  def test_pc_gets_its_own_budget_share_and_withheld_label
    host = pc_entry.resolved(example_defaults)

    assert_equal(
      { budget: 256_000, keep_free: 25_600, share: { cpus: 4, megabytes: 16_384 }, active_for: 300, withheld: %w[gpu] },
      settings_of(host)
    )
  end

  # The resolved host keeps its name and its runners.
  def test_a_resolved_host_keeps_its_name_and_runners
    host = pc_entry.resolved(example_defaults)

    assert_equal(["pc", %w[pc-windows pc-wsl]], [host.name, host.runners])
  end

  # Pool file reference, "`host`", `budget`: "Half the host's free disk space when `proof runner approve` adds the
  # host, written into its entry", so the budget has no built-in default. A budget in `defaults` serves a host that
  # has none.
  def test_a_budget_in_the_defaults_serves_a_host_with_none
    host = host_entry("nuc", %w[nuc-linux]).resolved(example_defaults)

    assert_equal(size("100GB"), host.budget)
  end

  # The same row: a host with no budget in its entry or in `defaults` is refused.
  def test_a_host_with_no_budget_anywhere_is_refused
    error = assert_raises(Proof::InvalidHostEntryError) do
      host_entry("nuc", %w[nuc-linux]).resolved(host_settings(active_for: "5m"))
    end

    assert_equal("the host \"nuc\" has no budget. Give its entry a budget, or give defaults one", error.message)
  end

  # Pool file reference, "`defaults`": "The settings every `host` gets unless its entry has a different value", so
  # with no `defaults` node a host gets the built-in defaults for what its entry lacks.
  def test_with_no_defaults_a_host_gets_the_built_in_defaults
    host = nuc_entry.resolved(Proof::HostSettings.new)

    assert_equal(
      { budget: 409_600, keep_free: 25_600, share: { cpus: 2, megabytes: 4096 }, active_for: 300, withheld: [] },
      settings_of(host)
    )
  end

  # The same sentence, for a setting that Proof's built-in defaults also give: `defaults` beats the built-in value, so
  # a `keep-free`, a share, and an `active-for` in `defaults` are the host's.
  def test_the_defaults_beat_the_built_in_defaults
    defaults = host_settings(keep_free: "10GB", share: [1, "1GB"], active_for: "10m")
    host = host_entry("nuc", %w[nuc-linux], budget: "1GB").resolved(defaults)

    assert_equal(
      { budget: 1024, keep_free: 10_240, share: { cpus: 1, megabytes: 1024 }, active_for: 600, withheld: [] },
      settings_of(host)
    )
  end

  # Pool file reference, "`defaults`", `withhold`: labels withheld by `defaults` and by the host add up.
  def test_withheld_labels_of_the_defaults_and_the_entry_add
    host = pc_entry.resolved(host_settings(budget: "1GB", withhold: %w[desktop]))

    assert_equal(Proof::LabelSet.of("gpu", "desktop"), host.withheld)
  end

  # A share of nothing in the entry is the host's share, not the defaults'.
  def test_a_share_of_nothing_beats_the_defaults
    host = host_entry("nuc", %w[nuc-linux], budget: "1GB", share: [0, "0GB"]).resolved(example_defaults)

    assert_equal({ cpus: 0, megabytes: 0 }, host.share.to_h)
  end
end
