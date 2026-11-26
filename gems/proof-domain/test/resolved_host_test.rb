# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks a host with every setting it gets, the value the server reads for each host.
class ResolvedHostTest < Minitest::Test
  include PoolFileHelper

  # Every member a resolved host is built from, as the page's `host` table lists them.
  def given(**changes)
    {
      name: "nuc",
      runners: %w[nuc-linux],
      budget: size("400GB"),
      keep_free: size("25GB"),
      share: share_of(2, "4GB"),
      active_for: duration("5m"),
      withheld: Proof::LabelSet.of,
    }.merge(changes)
  end

  # Pool file reference, "`host`", table: a resolved host has the host's name, runners, and each of the five settings.
  def test_a_resolved_host_keeps_what_it_is_built_from
    host = Proof::ResolvedHost.new(**given)

    assert_equal(
      ["nuc", %w[nuc-linux], size("400GB"), size("25GB"), share_of(2, "4GB"), duration("5m"), Proof::LabelSet.of],
      [host.name, host.runners, host.budget, host.keep_free, host.share, host.active_for, host.withheld]
    )
  end

  # A resolved host has every setting, so a setting that is missing is refused, and so is one of the wrong kind.
  def test_a_setting_that_is_missing_or_of_the_wrong_kind_is_refused
    %i[budget keep_free share active_for withheld].product([nil, 5]).each do |member, value|
      assert_raises(Proof::InvalidResolvedHostError, "#{member} #{value.inspect}") do
        Proof::ResolvedHost.new(**given(member => value))
      end
    end
  end

  # A name that is not text and runners that are not runner names are refused, as they are in an entry.
  def test_a_name_or_runners_that_are_not_valid_are_refused
    assert_raises(Proof::InvalidResolvedHostError) { Proof::ResolvedHost.new(**given(name: 5)) }
    assert_raises(Proof::InvalidResolvedHostError) { Proof::ResolvedHost.new(**given(runners: [])) }
  end

  # The message says which setting is missing.
  def test_the_message_names_the_missing_setting
    %i[budget keep_free share active_for withheld].each do |member|
      error = assert_raises(Proof::InvalidResolvedHostError) { Proof::ResolvedHost.new(**given(member => nil)) }

      assert_equal("a resolved host has every setting, and #{member} is missing", error.message)
    end
  end

  # A resolved host freezes its name and its runners, as the entry does, so what a caller keeps can't change it.
  def test_the_name_and_the_runners_are_frozen_copies
    runners = %w[nuc-linux]
    host = Proof::ResolvedHost.new(**given(name: +"nuc", runners:))
    runners << "nuc-wsl"

    assert_equal([%w[nuc-linux], true, true], [host.runners, host.runners.frozen?, host.name.frozen?])
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidResolvedHostError, :<, Proof::Error)
  end
end
