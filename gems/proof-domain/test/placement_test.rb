# frozen_string_literal: true

require_relative("support/placing")
require_relative("test_helper")

# Checks how the placement service chooses a runner for the next run.
class PlacementTest < Minitest::Test
  include Placing

  # Architecture, "Placing a run": placement "writes one fact to one run",
  # with the server's time.
  def test_placing_a_run_writes_one_placement_with_the_servers_time
    enqueue("aaaaa")
    placed = placement(host("nuc", runner("nuc-linux"))).place_next

    assert_equal(Proof::Run::Placed.new(at: NOW, host: "nuc", runner: "nuc-linux"), placed&.facts&.last)
    assert_equal(:running, runs.find(placed&.id || ID)&.state)
  end

  # Architecture, "Placing a run": the store refuses a fact added at a version
  # the run no longer has, so placement writes at the version it read, which is
  # the run's number of facts, not the first.
  def test_a_run_is_placed_at_the_version_read
    enqueue("aaaaa")
    read = runs.queued.each { |run| run.define_singleton_method(:version) { 3 } }
    error = assert_raises(Proof::RunChangedError) do
      placement(host("nuc", runner("nuc-linux")), store: stale(read)).place_next
    end

    assert_match(/has 1 facts, not the 3 it had when it was read/, error.message)
  end

  # A decision made from a run that another decision changed since is refused,
  # not written over it.
  def test_a_run_changed_since_it_was_read_is_not_placed
    enqueue("aaaaa")
    read = runs.queued
    runs.append(ids("aaaaa").first, Proof::Run::CancelAsked.new(at: NOW), version: 1)

    assert_raises(Proof::RunChangedError) { placement(host("nuc", runner("nuc-linux")), store: stale(read)).place_next }
  end

  # With no queued run, nothing is placed.
  def test_an_empty_queue_places_nothing
    assert_nil(placement(host("nuc", runner("nuc-linux"))).place_next)
  end

  # Each call is one decision, so a second call places the next run.
  def test_each_call_places_one_run
    enqueue("aaaaa")
    enqueue("bbbbb")
    nuc = host("nuc", runner("nuc-linux"))

    assert_equal(%w[aaaaa bbbbb], [placed_run(nuc), placed_run(nuc)])
  end

  # Server design, "Placement": "Count CPUs and memory per host, summing every
  # runner on it". A run on pc-windows leaves too little of the PC for pc-wsl.
  def test_a_hosts_resources_count_across_its_runners
    hold(holding("hhhhh", "pc", "pc-windows", asks: [12, "8GB"]))
    enqueue("aaaaa", asks: [8, "4GB"])
    pc = host("pc", runner("pc-windows", os: :windows, has: [16, "64GB"]), runner("pc-wsl", has: [16, "32GB"]))

    assert_nil(placed_on(pc))
  end

  # Server design, "Placement": "a run that fits the host but not the runner
  # must not be placed on that runner."
  def test_a_run_must_fit_its_runners_capacity
    enqueue("aaaaa", asks: [2, "12GB"])
    pc = host("pc", runner("pc-windows", os: :windows, has: [16, "64GB"]), runner("pc-wsl", has: [16, "8GB"]))

    assert_nil(placed_on(pc))
  end

  # A host's second runner takes a run as its first would.
  def test_a_run_goes_to_any_runner_of_a_host
    enqueue("aaaaa")
    pc = host("pc", runner("pc-windows", os: :windows), runner("pc-wsl"))

    assert_equal("pc-wsl", placed_on(pc))
  end

  # Server design, "Placement": "A run is placed only where its operating
  # system ... fit[s]".
  def test_a_run_goes_only_to_a_runner_of_its_operating_system
    enqueue("aaaaa", os: %i[windows])
    pc = host("pc", runner("pc-windows", os: :windows), runner("pc-wsl"))

    assert_equal("pc-windows", placed_on(pc))
  end

  # Server design, "Placement": a run is placed only where "every label it
  # needs" fits.
  def test_a_run_goes_only_to_a_runner_with_every_label_it_needs
    enqueue("aaaaa", labels: %w[gpu])
    nuc = host("nuc", runner("nuc-linux", has: [32, "128GB"]))
    pc = host("pc", runner("pc-wsl", labels: %w[gpu kvm]))

    assert_equal("pc-wsl", placed_on(nuc, pc))
  end

  # Server design, "Placement": "Among the runs that fit now, the one that
  # arrived first goes first".
  def test_the_earliest_run_that_fits_goes_first
    enqueue("aaaaa")
    enqueue("bbbbb")

    assert_equal("aaaaa", placed_run(host("nuc", runner("nuc-linux"))))
  end

  # Server design, "Placement": "a run that fits nowhere doesn't hold up the
  # runs behind it."
  def test_a_run_that_fits_nowhere_does_not_hold_up_the_runs_behind_it
    enqueue("aaaaa", os: %i[macos])
    enqueue("bbbbb", asks: [64, "4GB"])
    enqueue("ccccc")

    assert_equal("ccccc", placed_run(host("nuc", runner("nuc-linux"))))
  end

  # Server design, "Placement": "A host keeps its memory share free always".
  def test_no_run_is_placed_into_the_memory_share_with_nobody_active
    enqueue("aaaaa", asks: [2, "29GB"])
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]), share: size(2, "4GB"))

    assert_nil(placed_on(nuc))
  end

  # The memory outside the share is free.
  def test_a_run_up_to_the_memory_share_is_placed
    enqueue("aaaaa", asks: [2, "28GB"])
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]), share: size(2, "4GB"))

    assert_equal("nuc-linux", placed_on(nuc))
  end

  # Server design, "Placement": a host keeps "its CPU share free while a
  # person is active".
  def test_no_run_is_placed_into_the_cpu_share_while_a_person_is_active
    enqueue("aaaaa", asks: [7, "4GB"])
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]), share: size(2, "4GB"), active: true)

    assert_nil(placed_on(nuc))
  end

  # People at hosts, "Requirements": "When they stop, runs get the share's
  # CPUs back."
  def test_a_run_uses_the_cpu_share_with_nobody_active
    enqueue("aaaaa", asks: [8, "4GB"])
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]), share: size(2, "4GB"))

    assert_equal("nuc-linux", placed_on(nuc))
  end

  # Server design, "Placement": "Keep a run queued when its operating system
  # has no runner at the moment", and a runner that isn't connected can't
  # take a run.
  def test_a_runner_that_is_not_connected_gets_no_run
    enqueue("aaaaa")

    assert_nil(placed_on(host("nuc", runner("nuc-linux", connected: false))))
    assert_equal(:queued, runs.queued.first&.state)
  end
end
