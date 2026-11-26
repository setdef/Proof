# frozen_string_literal: true

require_relative("support/pool")
require_relative("test_helper")

# Checks how a host counts its free CPUs and memory from its runs.
class HostTest < Minitest::Test
  include Pool

  # Glossary, "capacity": "A host's capacity is the most that any of its
  # runners reports, of each."
  def test_a_hosts_capacity_is_the_most_any_runner_reports_of_each
    pc = host("pc", runner("pc-windows", has: [16, "8GB"]), runner("pc-wsl", has: [4, "64GB"]))

    assert_equal(size(16, "64GB"), pc.capacity)
  end

  # A host with no runners has nothing.
  def test_a_host_with_no_runners_has_no_capacity
    assert_equal(Proof::Resources.new(cpus: 0, megabytes: 0), host("nuc").capacity)
  end

  # Server design, "Placement": "Count CPUs and memory per host, summing every
  # runner on it".
  def test_runs_on_every_runner_of_a_host_count_against_it
    windows = runner("pc-windows", has: [16, "64GB"])
    wsl = runner("pc-wsl", has: [16, "64GB"])
    runs = [holding("aaaaa", "pc", "pc-wsl", asks: [4, "8GB"])]

    assert_equal(size(12, "56GB"), host("pc", windows, wsl).free_on(windows, runs))
  end

  # Server design, "Placement": "Two runners on one host must never be offered
  # the host's resources twice."
  def test_runs_on_two_runners_add_up
    windows = runner("pc-windows", has: [16, "64GB"])
    wsl = runner("pc-wsl", has: [16, "64GB"])
    on_wsl = holding("aaaaa", "pc", "pc-wsl", asks: [4, "4GB"])
    runs = [on_wsl, holding("bbbbb", "pc", "pc-windows", asks: [6, "4GB"], position: 2)]

    assert_equal(6, host("pc", windows, wsl).free_on(wsl, runs).cpus)
  end

  # Server design, "Placement": "A run must fit its runner's capacity as well
  # as its host's free resources."
  def test_a_runner_with_less_than_its_host_gives_no_more_than_it_has
    windows = runner("pc-windows", has: [16, "64GB"])
    wsl = runner("pc-wsl", has: [16, "8GB"])

    assert_equal(size(16, "8GB"), host("pc", windows, wsl).free_on(wsl, []))
  end

  # A runner's own runs count against its capacity, so WSL can't take two runs
  # that together need more memory than WSL has.
  def test_a_runners_own_runs_count_against_its_capacity
    wsl = runner("pc-wsl", has: [16, "8GB"])
    pc = host("pc", runner("pc-windows", has: [16, "64GB"]), wsl)

    assert_equal(size(14, "2GB"), pc.free_on(wsl, [holding("aaaaa", "pc", "pc-wsl", asks: [2, "6GB"])]))
  end

  # Server design, "Placement": "A host keeps its memory share free always".
  def test_a_host_keeps_its_memory_share_with_nobody_active
    nuc_linux = runner("nuc-linux", has: [8, "32GB"])
    nuc = host("nuc", nuc_linux, share: size(2, "4GB"))

    assert_equal(size(8, "28GB"), nuc.free_on(nuc_linux, []))
  end

  # Server design, "Placement": a host keeps "its CPU share free while a
  # person is active".
  def test_a_host_keeps_its_cpu_share_while_a_person_is_active
    nuc_linux = runner("nuc-linux", has: [8, "32GB"])
    nuc = host("nuc", nuc_linux, share: size(2, "4GB"), active: true)

    assert_equal(size(6, "28GB"), nuc.free_on(nuc_linux, []))
  end

  # What is free never goes below zero, even when runs and the share together
  # take more than the host has.
  def test_what_is_free_never_goes_below_zero
    nuc_linux = runner("nuc-linux", has: [2, "4GB"])
    nuc = host("nuc", nuc_linux, share: size(2, "4GB"), active: true)

    none = Proof::Resources.new(cpus: 0, megabytes: 0)

    assert_equal(none, nuc.free_on(nuc_linux, [holding("aaaaa", "nuc", "nuc-linux")]))
  end

  # Runs on another host, or by a runner that is no longer this host's, hold
  # nothing here. Server design, "Runs and their records": a lost run's
  # resources stay held "until the runner reports that the run's processes
  # ended, or the runner is revoked".
  def test_only_runs_on_this_hosts_runners_count
    nuc_linux = runner("nuc-linux")
    runs = [holding("aaaaa", "pc", "nuc-linux"), holding("bbbbb", "nuc", "nuc-old", position: 2)]

    assert_empty(host("nuc", nuc_linux).holding(runs))
  end

  # A queued run is placed nowhere, so it holds nothing.
  def test_a_queued_run_holds_nothing
    assert_empty(host("nuc", runner("nuc-linux")).holding([run_of(queued)]))
  end

  # Server design, "Placement": "Judge each host by what it could ever have
  # free, within its runner's capacity", which keeps the memory share and,
  # with nobody active, none of the CPUs.
  def test_what_a_host_could_ever_have_keeps_only_the_memory_share
    windows = runner("pc-windows", has: [16, "64GB"])
    wsl = runner("pc-wsl", has: [16, "8GB"])
    pc = host("pc", windows, wsl, share: size(4, "16GB"), active: true)

    assert_equal(size(16, "48GB"), pc.ever_on(windows))
    assert_equal(size(16, "8GB"), pc.ever_on(wsl))
  end

  # Glossary, "share": "The memory is free always ... and the CPUs are free
  # while a person is active".
  def test_a_host_keeps_its_share_by_whether_a_person_is_active
    assert_equal(size(2, "4GB"), host("nuc", share: size(2, "4GB"), active: true).kept)
    assert_equal(Proof::Resources.new(cpus: 0, megabytes: 4096), host("nuc", share: size(2, "4GB")).kept)
  end

  # Each value a host holds is checked.
  def test_a_host_with_a_value_of_the_wrong_kind_is_refused
    bad = [{ name: nil }, { name: "" }, { name: :nuc }, { share: "4GB" }, { person_active: 1 }]

    bad.each { |values| assert_raises(Proof::InvalidHostError) { Proof::Host.new(**good_values, **values) } }
  end

  # A host's runners are an Array of runners, and two runners of one host have
  # different names.
  def test_a_host_with_runners_of_the_wrong_kind_is_refused
    twice = [runner("nuc-linux"), runner("nuc-linux")]
    bad = [{ runners: [nil] }, { runners: twice }, { runners: Set[runner("nuc-linux")] }]

    bad.each { |values| assert_raises(Proof::InvalidHostError) { Proof::Host.new(**good_values, **values) } }
  end

  # A host keeps a frozen copy of its name, so a change to the string it was
  # given doesn't rename it.
  def test_a_host_keeps_a_frozen_copy_of_its_name
    given = +"nuc"

    assert_predicate(host(given).name, :frozen?)
    assert_predicate(host(given), :frozen?)
  end

  # A host keeps its own copy of its runners.
  def test_a_host_keeps_a_frozen_copy_of_its_runners
    given = [runner("nuc-linux")]
    nuc = host("nuc", *given)
    given << runner("nuc-wsl")

    assert_equal(1, nuc.runners.size)
    assert_predicate(nuc.runners, :frozen?)
  end

  private def good_values
    { name: "nuc", share: size(2, "4GB"), person_active: false, runners: [] }
  end
end
