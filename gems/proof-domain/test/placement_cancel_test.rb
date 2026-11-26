# frozen_string_literal: true

require_relative("support/placing")
require_relative("test_helper")

# Checks that placement leaves out a queued run whose cancel was asked for.
class PlacementCancelTest < Minitest::Test
  include Placing

  # Glossary, "run states": a run that is still `queued` ends `canceled` with
  # no runner, so a queued run whose cancel was asked for is never placed.
  def test_a_queued_run_whose_cancel_was_asked_for_is_not_placed
    enqueue("aaaaa")
    cancel_asked("aaaaa")

    assert_nil(placed_on(host("nuc", runner("nuc-linux"))))
    assert_nil(runs.find(ids("aaaaa").first)&.placement)
  end

  # A run whose cancel was asked for doesn't hold up the runs behind it, and
  # doesn't take the resources they need.
  def test_a_queued_run_whose_cancel_was_asked_for_does_not_hold_up_the_runs_behind_it
    enqueue("aaaaa")
    enqueue("bbbbb")
    cancel_asked("aaaaa")

    assert_equal("bbbbb", placed_run(host("nuc", runner("nuc-linux"))))
  end

  private def cancel_asked(characters)
    runs.append(ids(characters).first, Proof::Run::CancelAsked.new(at: NOW), version: 1)
  end
end
