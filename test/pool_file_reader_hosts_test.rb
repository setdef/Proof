# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks that the reader of the pool file builds the hosts and the defaults that the page says each form means.
class PoolFileReaderHostsTest < Minitest::Test
  include PoolFileReaderHelper

  NUC = "host nuc {\n  runner nuc-linux\n  budget \"400GB\"\n}\n"
  PC = "host pc {\n  runner pc-windows\n  runner pc-wsl\n  budget \"250GB\"\n  share cpus=4 memory=\"16GB\"\n  " \
    "withhold gpu\n}\n"
  MAC = "host mac {\n  runner mac-macos\n  budget \"1TB\"\n  keep-free \"50 GiB\"\n  share cpus=0 memory=\"0GB\"\n  " \
    "active-for \"10m\"\n  withhold gpu desktop\n}\n"
  private_constant(:NUC, :PC, :MAC)

  # The `mac` host of the text above, built by hand.
  def mac_entry
    settings = { budget: "1TB", keep_free: "50 GiB", share: [0, "0GB"], active_for: "10m", withhold: %w[gpu desktop] }

    host_entry("mac", %w[mac-macos], **settings)
  end

  # Pool file reference, "`defaults`": the block with `budget "100GB"`, `share cpus=2 memory="4GB"`, and
  # `active-for "5m"`, "The settings every `host` gets unless its entry has a different value."
  def test_the_page_example_of_the_defaults_node
    assert_equal(example_defaults, read(page_example("## `defaults`")).defaults)
  end

  # Pool file reference, "`host`": a file with no `defaults` node has defaults that give nothing, and Proof's built-in
  # defaults fill in the rest.
  def test_a_file_with_no_defaults_node_has_defaults_that_give_nothing
    assert_equal(Proof::HostSettings.new, read("").defaults)
  end

  # Pool file reference, "A complete example": `host nuc` with `runner nuc-linux` and `budget "400GB"`.
  def test_the_nuc_host_of_the_complete_example
    assert_equal([nuc_entry], read("defaults {\n  budget \"1GB\"\n}\n#{NUC}").hosts)
  end

  # The same example: `host pc` has two `runner` children, a budget, a share, and a withheld label, and the hosts are in
  # the order the file has them.
  def test_the_pc_host_of_the_complete_example_and_the_order_of_hosts
    assert_equal([pc_entry, nuc_entry], read("#{PC}#{NUC}").hosts)
  end

  # Pool file reference, "`host`": `runner RUNNER...` takes one or more runners, so one `runner` node may list several,
  # and they join the runners of the host's other `runner` nodes, in order.
  def test_a_runner_node_may_list_several_runners_and_be_given_again
    text = "host pc {\n  runner pc-windows pc-wsl\n  runner pc-extra\n  budget \"250GB\"\n}\n"

    assert_equal(%w[pc-windows pc-wsl pc-extra], read(text).hosts.first.runners)
  end

  # Pool file reference, "`host`", table: each of `keep-free` and `active-for` is a child that a host's entry may give,
  # and a host's `withhold` may list several labels.
  def test_a_host_may_give_every_child
    assert_equal([mac_entry], read(MAC).hosts)
  end

  # Pool file reference, "`defaults`": "It takes the same children as a `host`, except `runner`", so `defaults` may give
  # `keep-free` and `withhold` too.
  def test_the_defaults_may_give_every_child_but_runner
    text = "defaults {\n  budget \"1GB\"\n  keep-free \"10GB\"\n  share cpus=1 memory=\"1GB\"\n  " \
      "active-for \"1h\"\n  withhold gpu\n}\n"
    expected = host_settings(budget: "1GB", keep_free: "10GB", share: [1, "1GB"], active_for: "1h", withhold: %w[gpu])

    assert_equal(expected, read(text).defaults)
  end

  # Pool file reference, "`host`": "`proof runner approve` writes the entry with the host's runners and its budget, so
  # the host starts with the other settings in `defaults`", so a host's resolved settings come from its entry,
  # `defaults`, and Proof's built-in defaults.
  def test_each_hosts_resolved_settings_come_from_its_entry_then_the_defaults
    text = "defaults {\n  budget \"100GB\"\n  active-for \"5m\"\n}\nhost nuc {\n  runner nuc-linux\n}\n"
    host = read(text).resolved_hosts.first

    assert_equal(
      [size("100GB"), size("25GB"), share_of(2, "4GB"), duration("5m")],
      [host.budget, host.keep_free, host.share, host.active_for]
    )
  end

  # Pool file reference, "`host`", `budget`: "Half the host's free disk space when `proof runner approve` adds the host,
  # written into its entry", and the page gives no built-in budget, so a host with no budget in its entry or in
  # `defaults` is refused at the host's line, with what the domain says.
  def test_a_host_with_no_budget_in_its_entry_or_the_defaults_is_refused
    assert_refused(
      "server port=7443\n\nhost nuc {\n  runner nuc-linux\n}\n",
      3,
      domain_said(Proof::InvalidHostEntryError) do
        Proof::HostEntry.new(name: "nuc", runners: %w[nuc-linux]).resolved(Proof::HostSettings.new)
      end
    )
  end

  # Pool file reference, "Examples", "Keep more of the PC free for someone who games on it": the example has no budget,
  # so alone it is refused for that, and with a budget in `defaults` it reads as a host with
  # `share cpus=8 memory="32GB"`.
  def test_the_page_example_that_keeps_more_of_the_pc_free
    example = page_example("### Keep more of the PC free for someone who games on it")
    host = read("defaults {\n  budget \"100GB\"\n}\n#{example}").resolved_hosts.first

    assert_equal([%w[pc-windows pc-wsl], { cpus: 8, megabytes: 32_768 }], [host.runners, host.share.to_h])
    assert_raises(Proof::PoolFileError) { read(example) }
  end
end
