# frozen_string_literal: true

require_relative("support/pool")
require_relative("test_helper")

# Checks a runner as placement reads it.
class RunnerTest < Minitest::Test
  include Pool

  # How Proof works, "How the server places a run": "the runner's operating
  # system is one the project file lists for the task".
  def test_a_runner_takes_a_run_of_its_operating_system
    assert(runner("nuc-linux").takes?(queued(os: %i[linux macos])))
    refute(runner("mac-macos", os: :macos).takes?(queued(os: %i[linux windows])))
  end

  # How Proof works, "How the server places a run": "the runner has every
  # label the task needs".
  def test_a_runner_takes_a_run_only_with_every_label_it_needs
    assert(runner("nuc-linux", labels: %w[kvm gpu]).takes?(queued(labels: %w[kvm])))
    refute(runner("nuc-linux", labels: %w[kvm]).takes?(queued(labels: %w[kvm gpu])))
  end

  # A runner's name is frozen and kept as given.
  def test_a_runner_keeps_its_name
    assert_predicate(runner(+"pc-wsl").name, :frozen?)
    assert_equal("pc-wsl", runner("pc-wsl").name)
  end

  # Each value a runner holds is checked.
  def test_a_runner_with_a_value_of_the_wrong_kind_is_refused
    good = runner("nuc-linux").to_h
    bad = [{ name: "" }, { os: :linux }, { labels: ["kvm"] }, { capacity: "32GB" }, { connected: nil }]

    bad.each { |values| assert_raises(Proof::InvalidRunnerError) { Proof::Runner.new(**good, **values) } }
  end

  # The message names what it got.
  def test_the_message_says_what_the_runner_was_given
    error = assert_raises(Proof::InvalidRunnerError) { runner("nuc-linux", connected: "yes") }

    assert_equal('whether a runner is connected is true or false, not "yes"', error.message)
  end
end
