# frozen_string_literal: true

require_relative("run_facts")

# Builders for the hosts and runners placement reads, in the style guide's
# example pool: nuc, with nuc-linux, and pc, with pc-windows and pc-wsl.
module Pool
  include RunFacts

  # CPUs and memory, as a task writes them.
  def size(cpus, memory)
    Proof::Resources.request(cpus:, memory:)
  end

  # A runner of 8 CPUs and 32 GB, connected and with no labels, unless the test
  # says otherwise.
  def runner(name, os: :linux, has: [8, "32GB"], labels: [], connected: true)
    Proof::Runner.new(
      name:,
      os: Proof::OS.new(name: os),
      labels: Proof::LabelSet.of(*labels),
      capacity: size(*has),
      connected:
    )
  end

  # A host with these runners, keeping no share unless the test says otherwise.
  def host(name, *runners, share: Proof::Resources.new(cpus: 0, megabytes: 0), active: false)
    Proof::Host.new(name:, share:, person_active: active, runners:)
  end

  # A run with this ID's characters, queued at this position, and placed on
  # this host's runner when one is given.
  def holding(characters, host_name, runner_name, asks: [2, "4GB"], position: 1)
    cpus, memory = asks
    id = Proof::RunId.new(minute: AT, characters:)
    run_of(queued(position:, cpus:, memory:), placed(host: host_name, runner: runner_name), id:)
  end
end
