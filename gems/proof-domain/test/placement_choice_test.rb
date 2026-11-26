# frozen_string_literal: true

require_relative("support/placing")
require_relative("test_helper")

# Checks which runs hold a host's resources for placement, and which runner
# placement chooses among those that fit.
class PlacementChoiceTest < Minitest::Test
  include Placing

  # Server design, "Runs and their records": "The host's resources stay held
  # until the runner reports that the run's processes ended".
  def test_a_lost_run_holds_its_host_until_its_processes_end
    lost = run_of(queued(cpus: 8), placed, ended(:lost), id: Proof::RunId.new(minute: AT, characters: "11111"))
    hold(lost)
    enqueue("aaaaa", asks: [1, "1GB"])

    assert_nil(placed_on(host("nuc", runner("nuc-linux", has: [8, "32GB"]))))
  end

  # The same lost run, once its processes ended, holds nothing.
  def test_a_lost_run_whose_processes_ended_holds_nothing
    hold(run_of(queued(cpus: 8), placed, ended(:lost), processes_ended))
    enqueue("aaaaa", asks: [1, "1GB"])

    assert_equal("nuc-linux", placed_on(host("nuc", runner("nuc-linux", has: [8, "32GB"]))))
  end

  # Server design, "Runs and their records": a lost run holds its host's
  # resources until its processes end "or the runner is revoked".
  def test_a_run_by_a_runner_no_longer_on_its_host_holds_nothing
    hold(holding("hhhhh", "nuc", "nuc-revoked", asks: [8, "4GB"]))
    enqueue("aaaaa", asks: [8, "4GB"])

    assert_equal("nuc-linux", placed_on(host("nuc", runner("nuc-linux", has: [8, "32GB"]))))
  end

  # Of the runners that fit, the one with the most memory free goes first, so
  # runs spread across hosts, even over one with more CPUs free.
  def test_the_runner_with_the_most_memory_free_is_chosen
    enqueue("aaaaa")
    nuc = host("nuc", runner("nuc-linux", has: [16, "16GB"]))
    pc = host("pc", runner("pc-wsl", has: [4, "32GB"]))

    assert_equal("pc-wsl", placed_on(nuc, pc))
  end

  # With as much memory free, the runner with more CPUs free goes first.
  def test_with_as_much_memory_free_more_cpus_go_first
    enqueue("aaaaa")
    nuc = host("nuc", runner("nuc-linux", has: [4, "16GB"]))
    pc = host("pc", runner("pc-wsl", has: [8, "16GB"]))

    assert_equal("pc-wsl", placed_on(nuc, pc))
  end

  # With as much of both free, the first runner by name goes first, so a
  # decision is the same every time.
  def test_with_as_much_of_both_free_the_first_name_goes_first
    enqueue("aaaaa")
    hosts = [host("pc", runner("pc-wsl", has: [8, "16GB"])), host("nuc", runner("nuc-linux", has: [8, "16GB"]))]

    assert_equal("nuc-linux", placed_on(*hosts))
  end

  # Glossary, "place": placing a run holds its CPUs and memory, so the next
  # decision sees them in use.
  def test_a_placed_run_holds_its_host_for_the_next_decision
    enqueue("aaaaa", asks: [6, "4GB"])
    enqueue("bbbbb", asks: [6, "4GB"])
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]))

    assert_equal("aaaaa", placed_run(nuc))
    assert_nil(placed_run(nuc))
  end
end
