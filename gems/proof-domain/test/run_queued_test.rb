# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("test_helper")

# Checks the fact that a run was queued.
class RunQueuedTest < Minitest::Test
  include RunFacts

  # Glossary, "queue position": "A run's place in arrival order, given by the
  # server when the run is queued."
  def test_a_queued_run_keeps_its_position_and_where_it_may_go
    fact = queued(position: 3, os: %i[linux macos])

    assert_equal(3, fact.position)
    assert_equal(Set[Proof::OS.new(name: :linux), Proof::OS.new(name: :macos)], fact.os)
  end

  # Glossary, "label" and "resources": a run needs its labels on a runner, and
  # requests its CPUs and memory on a host.
  def test_a_queued_run_keeps_what_it_asks_for
    fact = queued(labels: %w[kvm], cpus: 4, memory: "8GB")

    assert_equal(Proof::LabelSet.of("kvm"), fact.labels)
    assert_equal(Proof::Resources.new(cpus: 4, megabytes: 8192), fact.resources)
  end

  # A queue position counts from 1.
  def test_a_queue_position_below_one_or_not_whole_is_refused
    [0, -1, 1.0, "1", nil].each do |position|
      error = assert_raises(Proof::InvalidFactError) { queued(position:) }

      assert_equal(format("a queue position is a whole number from 1, not %p", position), error.message)
    end
  end

  # Project file reference, "Children": `os` lists "One or more of `linux`,
  # `macos`, `windows`", so a run goes to at least one.
  def test_a_queued_run_needs_one_or_more_operating_systems
    error = assert_raises(Proof::InvalidFactError) { queued(os: []) }

    assert_equal("a queued run's os is one or more operating systems, not []", error.message)
  end

  # A queued run's operating systems are a frozen set, so a repeat counts once.
  def test_a_queued_runs_operating_systems_are_a_frozen_set
    fact = queued(os: %i[linux linux])

    assert_equal(1, fact.os.size)
    assert_predicate(fact.os, :frozen?)
  end

  # A queued run's operating systems are Proof::OS values.
  def test_operating_systems_that_are_not_os_values_are_refused
    labels = Proof::LabelSet.of
    resources = Proof::Resources.request(cpus: 1, memory: "1GB")

    assert_raises(Proof::InvalidFactError) do
      Proof::Run::Queued.new(at: AT, position: 1, os: [:linux], labels:, resources:)
    end
  end

  # Glossary, "label": "A task can require labels", held as a set of labels.
  def test_labels_that_are_not_a_label_set_are_refused
    os = [Proof::OS.new(name: :linux)]
    resources = Proof::Resources.request(cpus: 1, memory: "1GB")
    error = assert_raises(Proof::InvalidFactError) do
      Proof::Run::Queued.new(at: AT, position: 1, os:, labels: ["gpu"], resources:)
    end

    assert_equal(%(a queued run's labels are a set of labels, not ["gpu"]), error.message)
  end

  # Project file reference, "Properties": a task's `cpus` is a whole number
  # from 1, so a run requests at least 1 CPU.
  def test_a_queued_run_requests_at_least_one_cpu
    os = [Proof::OS.new(name: :linux)]
    resources = Proof::Resources.new(cpus: 0, megabytes: 1024)
    error = assert_raises(Proof::InvalidFactError) do
      Proof::Run::Queued.new(at: AT, position: 1, os:, labels: Proof::LabelSet.of, resources:)
    end

    assert_match(/\Aa queued run requests resources with at least 1 CPU, not /, error.message)
  end

  # A run's resources are Proof::Resources.
  def test_resources_that_are_not_resources_are_refused
    os = [Proof::OS.new(name: :linux)]

    assert_raises(Proof::InvalidFactError) do
      Proof::Run::Queued.new(at: AT, position: 1, os:, labels: Proof::LabelSet.of, resources: "4GB")
    end
  end

  # Project file reference, "Sizes": "0GB" is a size, so a request of no memory
  # is a request.
  def test_a_queued_run_may_request_no_memory
    assert_equal(0, queued(memory: "0GB").resources.megabytes)
  end
end
