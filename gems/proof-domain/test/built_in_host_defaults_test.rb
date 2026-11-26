# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks the settings that a host gets when neither its entry nor `defaults` gives one.
class BuiltInHostDefaultsTest < Minitest::Test
  include PoolFileHelper

  # Pool file reference, "`host`", table: `keep-free` is `"25GB"`, `share` is `cpus=2 memory="4GB"`, `active-for` is
  # `"5m"`, and `withhold` is "None".
  def test_the_built_in_defaults_are_the_pages_table
    settings = Proof::BuiltInHostDefaults::SETTINGS

    assert_equal(
      [size("25GB"), share_of(2, "4GB"), duration("5m"), Proof::LabelSet.of],
      [settings.keep_free, settings.share, settings.active_for, settings.withheld]
    )
  end

  # Pool file reference, "`host`", `budget`: "Half the host's free disk space when `proof runner approve` adds the
  # host, written into its entry", so the built-in defaults give no budget.
  def test_the_built_in_defaults_give_no_budget
    assert_nil(Proof::BuiltInHostDefaults::SETTINGS.budget)
  end
end
