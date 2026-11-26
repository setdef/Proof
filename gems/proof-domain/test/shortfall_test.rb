# frozen_string_literal: true

require_relative("test_helper")

# Checks what a host lacks for a run, as the refusal says it.
class ShortfallTest < Minitest::Test
  # CPUs and memory, as a task writes them.
  def size(cpus, memory)
    Proof::Resources.request(cpus:, memory:)
  end

  # Server design, "Placement": the message lists "every resource that host
  # lacks", CPUs first.
  def test_a_shortfall_is_listed_for_each_resource_the_host_lacks
    shortfalls = Proof::Shortfall.of(size(4, "8GB"), size(8, "16GB"))

    assert_equal(%i[cpus memory], shortfalls.map(&:resource))
    assert_equal([[4, 8], [8192, 16_384]], shortfalls.map { |each| [each.could_have, each.requested] })
  end

  # A resource the host has enough of isn't short.
  def test_a_resource_with_enough_is_not_listed
    assert_empty(Proof::Shortfall.of(size(8, "16GB"), size(8, "16GB")))
  end

  # The worst shortfall is the smallest part of the request a host could have.
  def test_a_fraction_is_the_part_of_the_request_the_host_could_have
    assert_equal(Rational(3, 4), Proof::Shortfall.new(resource: :cpus, could_have: 6, requested: 8).fraction)
  end

  # The message says CPUs as a count, with one CPU singular.
  def test_cpus_are_written_as_a_count
    assert_equal("6 of the 8 CPUs", Proof::Shortfall.new(resource: :cpus, could_have: 6, requested: 8).to_s)
    assert_equal("0 of the 1 CPU", Proof::Shortfall.new(resource: :cpus, could_have: 0, requested: 1).to_s)
  end

  # Project file reference, "Sizes": a size is written with a unit, so the
  # message writes whole gigabytes as GB and any other size in MB.
  def test_memory_is_written_as_a_size
    fourteen = Proof::Shortfall.new(resource: :memory, could_have: 14_336, requested: 16_384)

    assert_equal("14 GB of the 16 GB", fourteen.to_s)
    assert_equal("1536 MB of the 2 GB", Proof::Shortfall.new(resource: :memory, could_have: 1536, requested: 2048).to_s)
  end

  # A shortfall is of CPUs or memory, in whole amounts.
  def test_a_shortfall_of_another_kind_or_amount_is_refused
    [[:disk, 1, 2], [:cpus, -1, 2], [:memory, 1, 2.5], [:cpus, nil, 2]].each do |resource, could_have, requested|
      assert_raises(Proof::InvalidShortfallError) { Proof::Shortfall.new(resource:, could_have:, requested:) }
    end
  end
end
