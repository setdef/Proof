# frozen_string_literal: true

require_relative("support/placing")
require_relative("test_helper")

# Checks what a queued run waits behind.
class WaitReasonTest < Minitest::Test
  include Placing

  # The reason for a run queued with these settings, over these hosts and the
  # runs the test holds.
  def reason(*hosts, os: %i[linux], labels: [], asks: [2, "4GB"])
    cpus, memory = asks
    Proof::WaitReason.of(queued(os:, labels:, cpus:, memory:), hosts, runs.holding_resources)
  end

  # Server design, "Placement": `proof status` says "which runs hold the host
  # it needs", here in queue order.
  def test_a_run_waits_behind_the_runs_that_hold_its_host
    hold(
      holding("bbbbb", "nuc", "nuc-linux", asks: [4, "4GB"], position: 2),
      holding("aaaaa", "nuc", "nuc-linux", asks: [4, "4GB"], position: 1)
    )
    waiting = reason(host("nuc", runner("nuc-linux", has: [8, "32GB"])), asks: [4, "4GB"])

    assert_equal(Proof::WaitReason.new(kind: :behind_runs, hosts: %w[nuc], runs: ids("aaaaa", "bbbbb")), waiting)
  end

  # Server design, "Placement": `proof status` says "that a person is active
  # there".
  def test_a_run_waits_for_a_person_to_leave_when_only_the_cpu_share_is_in_the_way
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]), share: size(2, "4GB"), active: true)

    assert_equal(Proof::WaitReason.new(kind: :person_active, hosts: %w[nuc]), reason(nuc, asks: [8, "4GB"]))
  end

  # Runs on a host where a person is in the way aren't what the run waits
  # behind, so the reason names no run.
  def test_a_run_waiting_for_a_person_names_no_run
    hold(holding("aaaaa", "nuc", "nuc-linux", asks: [1, "4GB"]))
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]), share: size(2, "4GB"), active: true)

    assert_equal(Proof::WaitReason.new(kind: :person_active, hosts: %w[nuc]), reason(nuc, asks: [7, "4GB"]))
  end

  # The runs in the way across several hosts come in queue order, not host by
  # host.
  def test_the_runs_in_the_way_come_in_queue_order_across_hosts
    hold(
      holding("bbbbb", "nuc", "nuc-linux", asks: [8, "4GB"], position: 2),
      holding("aaaaa", "pc", "pc-wsl", asks: [8, "4GB"], position: 1)
    )
    hosts = [host("nuc", runner("nuc-linux", has: [8, "32GB"])), host("pc", runner("pc-wsl", has: [8, "32GB"]))]

    assert_equal(ids("aaaaa", "bbbbb"), reason(*hosts, asks: [8, "4GB"])&.runs)
  end

  # A host with two runners the run could go to is named once.
  def test_a_host_is_named_once_for_two_of_its_runners
    windows = runner("pc-windows", os: :windows, has: [8, "32GB"])
    pc = host("pc", windows, runner("pc-wsl", has: [8, "32GB"]), share: size(4, "4GB"), active: true)

    assert_equal(%w[pc], reason(pc, os: %i[linux windows], asks: [8, "4GB"])&.hosts)
  end

  # Server design, "Placement": `proof status` says "that no runner of its
  # operating system is connected".
  def test_a_run_whose_operating_system_has_no_runner_waits_for_one_to_connect
    nuc = host("nuc", runner("nuc-linux"))

    assert_equal(Proof::WaitReason.new(kind: :no_runner_connected), reason(nuc, os: %i[macos]))
  end

  # A runner that isn't connected can't take the run, so the run waits for it.
  def test_a_run_whose_only_runner_is_not_connected_waits_for_it
    mac = host("mac", runner("mac-macos", os: :macos, connected: false))

    assert_equal(Proof::WaitReason.new(kind: :no_runner_connected, hosts: %w[mac]), reason(mac, os: %i[macos]))
  end

  # A connected runner that could never have the run's resources free can't
  # take it either, so the run waits for one that can.
  def test_a_run_too_large_for_every_connected_runner_waits_for_another
    small = host("nuc", runner("nuc-linux", has: [2, "4GB"]))

    assert_equal(:no_runner_connected, reason(small, asks: [8, "4GB"])&.kind)
  end

  # A run that fits the PC but not the runner it would go to, such as WSL with
  # less memory than the PC, waits for another runner, as Server design,
  # "Placement", says: "A run must fit its runner's capacity".
  def test_a_run_too_large_for_the_runner_but_not_its_host_waits_for_another
    pc = host("pc", runner("pc-windows", os: :windows, has: [16, "64GB"]), runner("pc-wsl", has: [16, "8GB"]))

    assert_equal(:no_runner_connected, reason(pc, asks: [2, "12GB"])&.kind)
  end

  # Troubleshooting, "A run waits in the queue": "no runner offers a label it
  # needs".
  def test_a_run_waits_for_a_runner_that_offers_its_labels
    nuc = host("nuc", runner("nuc-linux", labels: %w[kvm]))

    assert_equal(Proof::WaitReason.new(kind: :no_label, hosts: %w[nuc]), reason(nuc, labels: %w[gpu]))
  end

  # Of several reasons, the nearest is shown: runs in the way end by
  # themselves, a person leaves, and a missing runner or label needs someone
  # to act.
  def test_the_nearest_reason_is_shown
    hold(holding("aaaaa", "nuc", "nuc-linux", asks: [8, "4GB"]))
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]))
    pc = host("pc", runner("pc-wsl", has: [8, "32GB"]), share: size(4, "4GB"), active: true)

    assert_equal(:behind_runs, reason(nuc, pc, asks: [8, "4GB"])&.kind)
  end

  # A person active ranks before a runner that isn't connected.
  def test_a_person_active_comes_before_a_runner_that_is_not_connected
    pc = host("pc", runner("pc-wsl", has: [8, "32GB"]), share: size(4, "4GB"), active: true)
    nuc = host("nuc", runner("nuc-linux", connected: false))

    assert_equal(:person_active, reason(nuc, pc, asks: [8, "4GB"])&.kind)
  end

  # A runner that isn't connected ranks before a runner without the label.
  def test_a_runner_not_connected_comes_before_a_missing_label
    nuc = host("nuc", runner("nuc-linux", labels: %w[gpu], connected: false))
    pc = host("pc", runner("pc-wsl"))

    waiting = reason(nuc, pc, labels: %w[gpu])

    assert_equal(Proof::WaitReason.new(kind: :no_runner_connected, hosts: %w[nuc]), waiting)
  end

  # Only runs on the hosts the run could fit count as in its way.
  def test_runs_on_hosts_the_run_does_not_fit_are_not_in_its_way
    hold(holding("aaaaa", "nuc", "nuc-linux", asks: [8, "4GB"]), holding("bbbbb", "mac", "mac-macos", position: 2))
    hosts = [host("nuc", runner("nuc-linux", has: [8, "32GB"])), host("mac", runner("mac-macos", os: :macos))]

    assert_equal(ids("aaaaa"), reason(*hosts, asks: [8, "4GB"])&.runs)
  end

  # A run that fits now waits behind nothing.
  def test_a_run_that_fits_now_has_no_reason
    assert_nil(reason(host("nuc", runner("nuc-linux"))))
  end

  # A reason's kind is one of the four.
  def test_a_reason_of_another_kind_is_refused
    error = assert_raises(Proof::InvalidWaitReasonError) { Proof::WaitReason.new(kind: :signing_in) }

    assert_equal(
      "a wait reason is one of behind_runs, person_active, no_runner_connected, no_label, not :signing_in",
      error.message
    )
  end

  # A reason keeps its own frozen copies of its hosts and runs.
  def test_a_reason_keeps_frozen_copies
    hosts = %w[nuc]
    waiting = Proof::WaitReason.new(kind: :person_active, hosts:)
    hosts << "pc"

    assert_equal(%w[nuc], waiting.hosts)
    assert_predicate(waiting.runs, :frozen?)
  end
end
