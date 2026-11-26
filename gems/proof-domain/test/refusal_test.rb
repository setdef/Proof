# frozen_string_literal: true

require_relative("support/placing")
require_relative("test_helper")

# Checks the refusal of a run no host could ever take.
class RefusalTest < Minitest::Test
  include Placing

  # The error checking a run of these settings over these hosts raises, or
  # nil when it raises none.
  def refusal_over(*hosts, os: %i[linux], labels: [], asks: [8, "16GB"])
    cpus, memory = asks
    placement(*hosts).check(queued(os:, labels:, cpus:, memory:))
    nil
  rescue Proof::RunFitsNoHostError => e
    e
  end

  # Server design, "Placement": "The host that fits the most is the one whose
  # worst shortfall is the smallest. A host with plenty of CPUs and too little
  # memory doesn't beat one that is close on both."
  def test_the_host_closest_on_both_beats_one_with_plenty_of_one
    nuc = host("nuc", runner("nuc-linux", has: [16, "8GB"]))
    pc = host("pc", runner("pc-wsl", has: [6, "14GB"]))

    assert_equal("pc", refusal_over(nuc, pc)&.host)
  end

  # Server design, "Placement": "Ranking by memory alone fails, because a
  # request can be short of CPUs too".
  def test_the_host_with_the_most_memory_does_not_win_when_short_of_cpus
    small = host("nuc", runner("nuc-linux", has: [2, "15GB"]))
    close = host("pc", runner("pc-wsl", has: [7, "12GB"]))

    assert_equal("pc", refusal_over(small, close)&.host)
  end

  # Server design, "Placement": "ranking by the sum of the shortfalls" fails.
  # A host short of two resources by 30% each has shortfalls that add up to
  # more than another's 50% of one, and still fits more of the request.
  def test_the_worst_shortfall_decides_not_their_sum
    one_short = host("nuc", runner("nuc-linux", has: [10, "5GB"]))
    both_short = host("pc", runner("pc-wsl", has: [7, "7GB"]))

    assert_equal("pc", refusal_over(one_short, both_short, asks: [10, "10GB"])&.host)
  end

  # Server design, "Placement": "The message lists every resource that host
  # lacks, with what the host could ever have free and what the run
  # requested."
  def test_the_message_lists_every_resource_the_closest_host_lacks
    error = refusal_over(host("pc", runner("pc-wsl", has: [6, "14GB"])))

    assert_equal(
      "No host could ever have the CPUs and memory this run requests free. The closest is pc, which could have " \
        "6 of the 8 CPUs and 14 GB of the 16 GB requested. Request less, or add a host with more.",
      error&.message
    )
  end

  # The message lists only what the host lacks.
  def test_a_resource_the_host_has_enough_of_is_not_listed
    error = refusal_over(host("nuc", runner("nuc-linux", has: [16, "8GB"])))

    assert_equal([Proof::Shortfall.new(resource: :memory, could_have: 8192, requested: 16_384)], error&.shortfalls)
  end

  # Server design, "Placement": "Judge each host by what it could ever have
  # free, within its runner's capacity", so WSL's memory counts, not the
  # PC's.
  def test_each_host_is_judged_within_its_runners_capacity
    pc = host("pc", runner("pc-windows", os: :windows, has: [16, "64GB"]), runner("pc-wsl", has: [16, "8GB"]))
    nuc = host("nuc", runner("nuc-linux", has: [16, "12GB"]))

    assert_equal("nuc", refusal_over(pc, nuc)&.host)
  end

  # Server design, "Placement": "A host keeps its memory share free always",
  # so the share is never free for a run.
  def test_what_a_host_could_ever_have_leaves_out_its_memory_share
    nuc = host("nuc", runner("nuc-linux", has: [16, "16GB"]), share: size(2, "4GB"))

    expected = [Proof::Shortfall.new(resource: :memory, could_have: 12_288, requested: 16_384)]

    assert_equal(expected, refusal_over(nuc)&.shortfalls)
  end

  # Server design, "Placement": the CPU share is kept only "while a person is
  # active", so a run that needs every CPU could have them some time.
  def test_a_run_that_needs_the_cpu_share_is_not_refused
    nuc = host("nuc", runner("nuc-linux", has: [8, "32GB"]), share: size(2, "4GB"), active: true)

    assert_nil(refusal_over(nuc, asks: [8, "16GB"]))
  end

  # A run that fits a host some time is not refused, however busy the host is
  # now.
  def test_a_run_that_fits_a_busy_host_is_not_refused
    hold(holding("hhhhh", "nuc", "nuc-linux", asks: [8, "32GB"]))

    assert_nil(refusal_over(host("nuc", runner("nuc-linux", has: [8, "32GB"]))))
  end

  # A run that fits one host is not refused because another host is too small
  # for it, in whichever order the hosts come.
  def test_a_run_that_fits_one_host_is_not_refused_for_a_small_host
    big = host("nuc", runner("nuc-linux", has: [16, "32GB"]))
    small = host("pc", runner("pc-wsl", has: [2, "4GB"]))

    assert_nil(refusal_over(small, big))
    assert_nil(refusal_over(big, small))
  end

  # Server design, "Placement": "Keep a run queued when its operating system
  # has no runner at the moment, since hosts come back."
  def test_a_run_whose_operating_system_has_no_runner_is_not_refused
    assert_nil(refusal_over(host("nuc", runner("nuc-linux", has: [2, "4GB"])), os: %i[macos]))
  end

  # A runner that isn't connected can come back, so it counts.
  def test_a_runner_that_is_not_connected_counts
    nuc = host("nuc", runner("nuc-linux", has: [16, "32GB"], connected: false))

    assert_nil(refusal_over(nuc))
  end

  # Only runners with the run's labels are judged: a large host without the
  # GPU can't take a run that needs one.
  def test_only_runners_with_the_runs_labels_are_judged
    nuc = host("nuc", runner("nuc-linux", has: [32, "128GB"]))
    pc = host("pc", runner("pc-wsl", labels: %w[gpu], has: [8, "8GB"]))

    assert_equal("pc", refusal_over(nuc, pc, labels: %w[gpu])&.host)
  end

  # A run no runner offers the labels for waits for one, and isn't refused.
  def test_a_run_whose_labels_no_runner_offers_is_not_refused
    assert_nil(refusal_over(host("nuc", runner("nuc-linux", has: [2, "4GB"])), labels: %w[gpu]))
  end

  # Of two hosts that fit as much, the first runner by name is named, so the
  # message is the same every time.
  def test_a_tie_names_the_first_runner_by_name
    hosts = [host("pc", runner("pc-wsl", has: [4, "8GB"])), host("nuc", runner("nuc-linux", has: [4, "8GB"]))]

    assert_equal("nuc", refusal_over(*hosts)&.host)
  end
end
