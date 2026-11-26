# frozen_string_literal: true

require_relative("test_helper")

# Checks taking resources from resources, and the least and the most of each.
class ResourcesArithmeticTest < Minitest::Test
  # Resources of the given CPUs and megabytes.
  def resources(cpus, megabytes)
    Proof::Resources.new(cpus:, megabytes:)
  end

  # Glossary, "shortfall": what a host could ever have free is its capacity
  # less the memory of its share, so a difference is taken from each resource.
  def test_minus_takes_each_resource_from_its_own
    assert_equal(resources(6, 12_288), resources(8, 16_384).minus(resources(2, 4096)))
  end

  # Glossary, "share": a share larger than what a host has leaves nothing, and
  # nothing free must never read as room, so a difference stops at 0.
  def test_minus_stops_at_zero_for_each_resource_on_its_own
    assert_equal(resources(0, 12_288), resources(8, 16_384).minus(resources(9, 4096)))
    assert_equal(resources(6, 0), resources(8, 16_384).minus(resources(2, 16_385)))
  end

  # Taking exactly what is there leaves nothing, and taking nothing leaves it
  # all.
  def test_minus_of_equal_and_of_no_resources
    assert_equal(Proof::Resources.none, resources(8, 16_384).minus(resources(8, 16_384)))
    assert_equal(resources(8, 16_384), resources(8, 16_384).minus(Proof::Resources.none))
  end

  # Glossary, "capacity": a host's capacity is the most that any of its
  # runners reports, of each, so a result can mix the CPUs of one runner with
  # the memory of another.
  def test_most_takes_the_larger_of_each_resource_on_its_own
    assert_equal(resources(16, 32_768), resources(16, 8192).most(resources(4, 32_768)))
    assert_equal(resources(16, 32_768), resources(4, 32_768).most(resources(16, 8192)))
  end

  # The most of several resources starts from none, as a host with no runners
  # has no capacity.
  def test_none_has_no_cpus_and_no_memory
    assert_equal([0, 0], [Proof::Resources.none.cpus, Proof::Resources.none.megabytes])
    assert_equal(resources(4, 8192), Proof::Resources.none.most(resources(4, 8192)))
  end

  # Glossary, "shortfall": a run goes where it fits the host and the runner,
  # so what it can have is the lesser of each resource.
  def test_least_takes_the_smaller_of_each_resource_on_its_own
    assert_equal(resources(4, 8192), resources(16, 8192).least(resources(4, 32_768)))
    assert_equal(resources(4, 8192), resources(4, 32_768).least(resources(16, 8192)))
  end

  # Equal resources are their own least and most.
  def test_least_and_most_of_equal_resources_are_those_resources
    assert_equal(resources(4, 8192), resources(4, 8192).least(resources(4, 8192)))
    assert_equal(resources(4, 8192), resources(4, 8192).most(resources(4, 8192)))
  end

  # Value objects are immutable, so arithmetic builds new ones.
  def test_arithmetic_leaves_the_receiver_and_the_argument_as_they_were
    first = resources(8, 16_384)
    second = resources(2, 4096)
    first.minus(second)
    first.least(second)
    first.most(second)

    assert_equal([resources(8, 16_384), resources(2, 4096)], [first, second])
  end
end
