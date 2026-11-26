# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks that the pool file compares the names of hosts, runners, and repositories without regard to case, and keeps
# each as its entry writes it.
class PoolNamesCaseTest < Minitest::Test
  include PoolFileHelper

  # The message of refusing a pool file with these hosts, with the defaults that give each a budget.
  def refusal_of_hosts(*hosts)
    error = assert_raises(Proof::InvalidPoolFileError) { Proof::PoolFile.new(defaults: example_defaults, hosts:) }

    error.message
  end

  # A repository entry named this, with a URL and the one branch and task that the entry needs.
  def repository_named(name)
    repository_entry(name, "https://example.com/#{name}.git", branches: %w[trunk], tasks: %w[test])
  end

  # Pool file reference, "What happens when the file has a mistake": "Proof compares the names of hosts, runners, and
  # repositories without regard to case, as it does labels, so `nuc` and `NUC` are one host, and a second entry for it
  # is refused." The message is the one for a repeated host, and names the first entry as it was written.
  def test_two_hosts_that_differ_only_in_case_are_refused_as_one_name_written_twice
    [%w[nuc NUC], %w[NUC nuc], %w[Nuc nUC]].each do |first, second|
      message = refusal_of_hosts(host_entry(first, %w[a]), host_entry(second, %w[b]))

      assert_equal("two hosts are named #{first.inspect}. Each host has one entry, so merge them into one", message)
    end
  end

  # The same for repositories.
  def test_two_repositories_that_differ_only_in_case_are_refused_as_one_name_written_twice
    error = assert_raises(Proof::InvalidPoolFileError) do
      Proof::PoolFile.new(repositories: [repository_named("Lota"), repository_named("LOTA")])
    end

    assert_equal(
      "two repositories are named \"Lota\". Each repository has one entry, so merge them into one", error.message
    )
  end

  # A repeat after other names is found, and a name between the two that is not a repeat is not named.
  def test_a_repeat_that_is_not_next_to_its_first_is_refused
    hosts = [host_entry("a", %w[r1]), host_entry("b", %w[r2]), host_entry("c", %w[r3]), host_entry("B", %w[r4])]

    assert_equal("two hosts are named \"b\". Each host has one entry, so merge them into one", refusal_of_hosts(*hosts))
  end

  # Glossary, "runner": "One operating system on a host", so a runner on two hosts is refused whatever the case of its
  # name on each, and the message names the runner as the first host lists it, and the two hosts as written.
  def test_a_runner_on_two_hosts_in_any_mix_of_case_is_refused
    [%w[nuc-linux NUC-Linux], %w[NUC-LINUX nuc-linux]].each do |first, second|
      message = refusal_of_hosts(host_entry("nuc", [first]), host_entry("Pc", %w[pc-wsl]), host_entry("mac", [second]))

      assert_equal(
        "the runner #{first.inspect} is listed on the hosts \"nuc\" and \"mac\". " \
          "A runner is one operating system on one host, so list it on one",
        message
      )
    end
  end

  # A runner twice on one host is refused whatever the case, as a runner listed twice is.
  def test_a_runner_twice_on_one_host_in_any_mix_of_case_is_refused
    [%w[pc-wsl PC-WSL], %w[PC-wsl pc-WSL]].each do |runners|
      error = assert_raises(Proof::InvalidHostEntryError) { Proof::HostEntry.new(name: "pc", runners:) }

      assert_equal(
        "a host entry's runners are one or more runner names that differ without regard to case, " \
          "each #{Proof::Name::TEXT}, such as [\"nuc-linux\"], not #{runners.inspect}",
        error.message
      )
    end
  end

  # The pool file of hosts and repositories whose names have capitals.
  def file_with_capitals
    Proof::PoolFile.new(
      defaults: example_defaults,
      hosts: [host_entry("Nuc", %w[Nuc-Linux]), host_entry("PC", %w[pc-Windows PC-wsl])],
      repositories: [repository_named("Lota"), repository_named("OTHER")]
    )
  end

  # Each name keeps its case as its entry writes it: in the file's entries, in the hosts resolved from them, and in the
  # repositories.
  def test_every_name_keeps_its_case_as_written
    file = file_with_capitals

    assert_equal([%w[Nuc PC], %w[Lota OTHER]], [file.hosts.map(&:name), file.repositories.map(&:name)])
    assert_equal(
      [%w[Nuc PC], [%w[Nuc-Linux], %w[pc-Windows PC-wsl]]],
      [file.resolved_hosts.map(&:name), file.resolved_hosts.map(&:runners)]
    )
  end

  # A host and a repository may share a name, in any case, as they are entries of different kinds, and a branch and a
  # task are compared as written, since Git's branches are.
  def test_names_of_different_kinds_are_not_repeats_and_branches_and_tasks_compare_as_written
    file = Proof::PoolFile.new(
      defaults: example_defaults,
      hosts: [host_entry("lota", %w[a])],
      repositories: [repository_entry("LOTA", "u", branches: %w[trunk Trunk], tasks: %w[test Test])]
    )

    assert_equal([%w[trunk Trunk], %w[test Test]], [file.repositories.first.branches, file.repositories.first.tasks])
  end
end
