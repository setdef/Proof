# frozen_string_literal: true

require_relative("pool")

# A store of runs, a pool's hosts, and the placement service over them, for
# placement tests.
module Placing
  include Pool

  NOW = Time.utc(2026, 11, 25, 3, 40)
  HOSTS = Data.define(:hosts)
  CLOCK = Data.define(:now)
  public_constant(:NOW, :HOSTS, :CLOCK)

  # The store the test's runs go into.
  def runs
    @runs ||= Proof::InMemory::Runs.new
  end

  # Stores a run queued at the next position with this ID's characters.
  def enqueue(characters, os: %i[linux], labels: [], asks: [2, "4GB"])
    cpus, memory = asks
    fact = queued(position: runs.next_position, os:, labels:, cpus:, memory:)
    runs.add(run_of(fact, id: Proof::RunId.new(minute: AT, characters:)))
  end

  # Stores runs that hold resources, each placed as given.
  def hold(*held)
    held.each { |run| runs.add(run) }
  end

  # The placement service over the test's runs and these hosts.
  def placement(*hosts)
    Proof::Placement.new(runs:, hosts: HOSTS.new(hosts:), clock: CLOCK.new(now: NOW))
  end

  # The runner the next placement over these hosts chooses, or nil.
  def placed_on(*hosts)
    placement(*hosts).place_next&.placement&.runner
  end

  # The characters of the run the next placement over these hosts places.
  def placed_run(*hosts)
    placement(*hosts).place_next&.id&.characters
  end
end
