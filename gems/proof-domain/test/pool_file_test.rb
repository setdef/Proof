# frozen_string_literal: true

require_relative("pool_file_helper")
require_relative("test_helper")

# Checks what the pool file holds, and the rules that span its hosts and its repositories.
class PoolFileTest < Minitest::Test
  include PoolFileHelper

  WRONG_PARTS = [
    { retention: 90 },
    { limits: nil },
    { defaults: {} },
    { hosts: nil },
    { hosts: [1] },
    { repositories: nil },
    { repositories: [1] },
  ].freeze
  private_constant(:WRONG_PARTS)

  # Pool file reference, "A complete example": the file holds the server's port, how long to keep runs, the most to
  # keep from a run, the defaults, two hosts, and one repository, each as it is written.
  def test_the_complete_example_holds_what_the_page_writes
    file = complete_example
    names = [file.hosts, file.repositories].map { |entries| entries.map(&:name) }

    parts = [file.port.number, file.retention.runs, file.limits.output, file.defaults, names]

    assert_equal([7443, days("90d"), size("1GB"), example_defaults, [%w[nuc pc], %w[lota]]], parts)
  end

  # Pool file reference, "`server`": `port` has the default `7443`, "`retention`" and "`limits`" have the defaults the
  # page lists, and a file with no `defaults`, no `host`, and no `repository` has none of them, as `proof server setup`
  # writes it before a runner joins.
  def test_a_pool_file_with_nothing_has_the_defaults
    file = Proof::PoolFile.new

    assert_equal(
      [Proof::Port.new(number: 7443), Proof::Retention.new, Proof::Limits.new, Proof::HostSettings.new, [], []],
      [file.port, file.retention, file.limits, file.defaults, file.hosts, file.repositories]
    )
  end

  # Pool file reference, "`server`": `port` is "A port number", so the pool file holds the port it is given.
  def test_a_pool_file_holds_its_port
    assert_equal(Proof::Port.new(number: 8443), Proof::PoolFile.new(port: Proof::Port.new(number: 8443)).port)
  end

  # The same row: a port number that isn't wrapped in a `Proof::Port` is not a port, so the rule for a port lives in
  # one value.
  def test_a_port_that_is_not_a_port_value_is_refused
    [7443, "7443", nil].each do |port|
      error = assert_raises(Proof::InvalidPoolFileError, port.inspect) { Proof::PoolFile.new(port:) }

      assert_equal("a pool file's port is a Proof::Port, not #{port.inspect}", error.message)
    end
  end

  # Pool file reference: each part of the file is the kind the page says: retention, limits, defaults, hosts, and
  # repositories.
  def test_a_part_of_the_wrong_kind_is_refused
    WRONG_PARTS.each do |change|
      assert_raises(Proof::InvalidPoolFileError, change.inspect) { Proof::PoolFile.new(**change) }
    end
  end

  # Pool file reference, "`host`": "One entry for each physical computer", so two hosts with one name are refused.
  def test_two_hosts_with_one_name_are_refused
    error = assert_raises(Proof::InvalidPoolFileError) do
      Proof::PoolFile.new(defaults: example_defaults, hosts: [nuc_entry, host_entry("nuc", %w[nuc-wsl])])
    end

    assert_equal("two hosts are named \"nuc\". Each host has one entry, so merge them into one", error.message)
  end

  # Pool file reference, glossary "runner": "One operating system on a host", so one runner name on two hosts is
  # refused, and the message names both hosts, and no host between them that lacks the runner.
  def test_a_runner_on_two_hosts_is_refused
    hosts = [nuc_entry, pc_entry, host_entry("mac", %w[mac-macos nuc-linux])]
    error = assert_raises(Proof::InvalidPoolFileError) { Proof::PoolFile.new(defaults: example_defaults, hosts:) }

    assert_equal(
      "the runner \"nuc-linux\" is listed on the hosts \"nuc\" and \"mac\". " \
        "A runner is one operating system on one host, so list it on one",
      error.message
    )
  end

  # Pool file reference, "`repository`": "`proof status` shows its runs under `NAME`", so two repositories with one name
  # are refused.
  def test_two_repositories_with_one_name_are_refused
    other = repository_entry("lota", "https://example.com/lota.git", branches: %w[trunk], tasks: %w[test])
    error = assert_raises(Proof::InvalidPoolFileError) { Proof::PoolFile.new(repositories: [lota_entry, other]) }

    assert_equal(
      "two repositories are named \"lota\". Each repository has one entry, so merge them into one", error.message
    )
  end

  # Pool file reference, "`host`", `budget`: no built-in default, so a pool file whose host has no budget in its entry
  # or in `defaults` is refused, and the error names the host.
  def test_a_host_with_no_budget_is_refused
    error = assert_raises(Proof::InvalidHostEntryError) { Proof::PoolFile.new(hosts: [host_entry("nuc", %w[nuc-linux])]) }

    assert_includes(error.message, "\"nuc\"")
  end

  # A budget in `defaults` serves a host with none, so the same host in a file with that `defaults` is accepted.
  def test_a_budget_in_the_defaults_serves_every_host
    file = Proof::PoolFile.new(defaults: host_settings(budget: "100GB"), hosts: [host_entry("nuc", %w[nuc-linux])])

    assert_equal(size("100GB"), file.resolved_hosts.first.budget)
  end

  # Pool file reference, "A complete example": "On `nuc`, Proof may use 400 GB of disk. On `pc`, Proof may use 250 GB,
  # keeps 16 GB of memory free always and 4 CPUs free while someone is active there, and never offers the PC's GPU to
  # a task." Each host's resolved settings are what that says, in the order of the file.
  def test_each_hosts_resolved_settings_are_what_the_page_says
    nuc, pc = complete_example.resolved_hosts

    assert_equal(
      [["nuc", 409_600, []], ["pc", 256_000, %w[gpu]]],
      [nuc, pc].map { |host| [host.name, host.budget.megabytes, host.withheld.labels.map(&:to_s)] }
    )
    assert_equal({ cpus: 4, megabytes: 16_384 }, pc.share.to_h)
  end

  # The hosts and repositories are frozen copies, so a list a caller keeps can't change the file.
  def test_the_hosts_and_the_repositories_are_frozen_copies
    hosts = [nuc_entry]
    file = Proof::PoolFile.new(defaults: example_defaults, hosts:)
    hosts << pc_entry

    assert_equal([1, true, true], [file.hosts.size, file.hosts.frozen?, file.repositories.frozen?])
  end

  # A keyword that the file doesn't have is Ruby's error, as for any keyword a method doesn't take.
  def test_a_keyword_that_the_file_does_not_have_is_refused
    assert_raises(ArgumentError) { Proof::PoolFile.new(host: []) }
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidPoolFileError, :<, Proof::Error)
  end
end
