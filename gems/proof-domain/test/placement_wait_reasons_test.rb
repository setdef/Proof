# frozen_string_literal: true

require_relative("support/placing")
require_relative("test_helper")

# Checks what the placement service says each queued run waits behind.
class PlacementWaitReasonsTest < Minitest::Test
  include Placing

  # Server design, "Placement": "`proof status` must say what each queued run
  # waits behind", by run, and a run that fits waits behind nothing.
  def test_placement_gives_the_reason_of_each_queued_run_that_does_not_fit
    enqueue("aaaaa", os: %i[macos])
    enqueue("bbbbb")
    reasons = placement(host("nuc", runner("nuc-linux"))).wait_reasons

    assert_equal({ ids("aaaaa").first => Proof::WaitReason.new(kind: :no_runner_connected) }, reasons)
  end

  # A queued run whose cancel was asked for ends `canceled` without a runner,
  # so it waits behind nothing.
  def test_placement_gives_no_reason_for_a_queued_run_whose_cancel_was_asked_for
    enqueue("aaaaa", os: %i[macos])
    runs.append(ids("aaaaa").first, Proof::Run::CancelAsked.new(at: NOW), version: 1)

    assert_empty(placement(host("nuc", runner("nuc-linux"))).wait_reasons)
  end

  # Server design, "Placement": `proof status` says "which runs hold the host
  # it needs", for each queued run.
  def test_placement_gives_the_runs_each_queued_run_waits_behind
    hold(holding("hhhhh", "nuc", "nuc-linux", asks: [8, "4GB"]))
    enqueue("aaaaa", asks: [8, "4GB"])
    reasons = placement(host("nuc", runner("nuc-linux", has: [8, "32GB"]))).wait_reasons

    assert_equal(
      { ids("aaaaa").first => Proof::WaitReason.new(kind: :behind_runs, hosts: %w[nuc], runs: ids("hhhhh")) }, reasons
    )
  end
end
