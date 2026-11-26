# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks one `host` entry of the pool file: its name, its runners, and its settings.
class HostEntryTest < Minitest::Test
  include PoolFileHelper

  # Pool file reference, "A complete example": `host nuc` has the runner `nuc-linux` and a budget of `"400GB"`, and
  # `host pc` has `pc-windows` and `pc-wsl`, a budget of `"250GB"`, a share, and `withhold gpu`.
  def test_the_complete_examples_hosts_are_what_their_entries_say
    assert_equal(
      [["nuc", %w[nuc-linux], size("400GB")], ["pc", %w[pc-windows pc-wsl], size("250GB")]],
      [nuc_entry, pc_entry].map { |entry| [entry.name, entry.runners, entry.settings.budget] }
    )
  end

  # Pool file reference, "`host`": `runner RUNNER...` names "The runners on this host", in the order the file lists
  # them.
  def test_the_runners_keep_their_order
    assert_equal(%w[pc-wsl pc-windows], host_entry("pc", %w[pc-wsl pc-windows], budget: "1GB").runners)
  end

  # Pool file reference, "`host`": an entry that gives no setting has settings that give nothing, which `defaults` and
  # Proof's built-in defaults then fill in.
  def test_an_entry_with_no_settings_has_settings_that_give_nothing
    assert_equal(Proof::HostSettings.new, Proof::HostEntry.new(name: "nuc", runners: %w[nuc-linux]).settings)
  end

  # Pool file reference, "`host`": the table's `runner` default is "Written by `proof runner approve`", so a host lists
  # one or more runners, and a host with none is refused.
  def test_a_host_with_no_runner_is_refused
    assert_raises(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: "nuc", runners: []) }
  end

  # Pool file reference, "`runner`": the server counts the runners of a host "as one host's", and glossary "runner":
  # one operating system on one host, so a runner listed twice on a host is refused.
  def test_a_runner_listed_twice_is_refused
    assert_raises(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: "pc", runners: %w[pc-wsl pc-wsl]) }
  end

  # Pool file reference, "`host`": `host NAME`, so a name is text of at least one character, and so is each runner.
  def test_a_name_or_a_runner_that_is_not_text_is_refused
    refused = [[5, %w[a]], ["", %w[a]], [nil, %w[a]], ["nuc", [5]], ["nuc", [""]], ["nuc", "nuc-linux"], ["nuc", nil]]

    refused.each do |name, runners|
      assert_raises(Proof::InvalidHostEntryError, [name, runners].inspect) { Proof::HostEntry.new(name:, runners:) }
    end
  end

  # The settings of an entry are host settings.
  def test_settings_that_are_not_host_settings_are_refused
    assert_raises(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: "nuc", runners: %w[a], settings: {}) }
  end

  # The messages name what is wrong and what it got.
  def test_the_messages_name_the_member
    messages = [
      [{ name: 5, runners: %w[a] }, "a host entry's name is a name, not 5"],
      [{ name: "a", runners: [] }, "a host entry's runners are one or more runner names that differ, not []"],
      [{ name: "a", runners: %w[a], settings: 1 }, "a host entry's settings are host settings, not 1"],
    ]

    messages.each do |given, message|
      error = assert_raises(Proof::InvalidHostEntryError) { Proof::HostEntry.new(**given) }

      assert_equal(message, error.message)
    end
  end

  # The entry freezes its runners and its name, so a list or a string a caller keeps can't change it.
  def test_the_name_and_the_runners_are_frozen_copies
    name = +"pc"
    runners = %w[pc-windows]
    entry = Proof::HostEntry.new(name:, runners:)
    runners << "pc-wsl"
    name << "x"

    assert_equal(
      [%w[pc-windows], true, "pc", true], [entry.runners, entry.runners.frozen?, entry.name, entry.name.frozen?]
    )
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidHostEntryError, :<, Proof::Error)
  end
end
