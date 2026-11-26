# frozen_string_literal: true

require_relative("test_helper")

# Checks when what a task requests fits within what a host has free.
class ResourcesFitTest < Minitest::Test
  # A request of 4 CPUs and the given memory size.
  def request(memory, cpus: 4)
    Proof::Resources.request(cpus:, memory:)
  end

  # Project file reference, "Properties": the server places a run "only on a
  # host with this many CPUs free", and a host with all its CPUs in use has 0
  # free, so no request fits within it.
  def test_a_request_does_not_fit_within_a_host_with_no_cpus_free
    refute(request("1GB", cpus: 1).fits_within?(Proof::Resources.new(cpus: 0, megabytes: 4096)))
  end

  # Pool file reference, "Properties" of a host: a share of `cpus=0
  # memory="0GB"` is accepted, and nothing but nothing fits within it.
  def test_resources_of_zero_cpus_fit_within_a_host_with_none_free
    assert(Proof::Resources.new(cpus: 0, megabytes: 0).fits_within?(Proof::Resources.new(cpus: 0, megabytes: 0)))
    refute(Proof::Resources.new(cpus: 0, megabytes: 1).fits_within?(Proof::Resources.new(cpus: 0, megabytes: 0)))
  end

  # Zero CPUs fit within any host: they ask for none.
  def test_zero_cpus_fit_within_a_host_with_cpus_free
    assert(Proof::Resources.new(cpus: 0, megabytes: 0).fits_within?(request("1GB", cpus: 1)))
  end

  # Project file reference, "Properties": the server "places a run only on a
  # host with this many CPUs free" and "only where this much is free", so a
  # request with what the host has free fits.
  def test_a_request_equal_to_what_is_free_fits
    assert(request("8GB").fits_within?(request("8GB")))
  end

  # Glossary, "resources": "The server places a run only where a host has the
  # resources free."
  def test_a_request_below_what_is_free_fits
    assert(request("8GB", cpus: 2).fits_within?(request("16GB", cpus: 8)))
  end

  # Project file reference, "Properties": the server places a run "only on a
  # host with this many CPUs free", so one CPU too few does not fit.
  def test_a_request_for_more_cpus_than_are_free_does_not_fit
    refute(request("8GB", cpus: 5).fits_within?(request("16GB", cpus: 4)))
  end

  # Project file reference, "Properties": the server places a run "only where
  # this much is free", so one megabyte too few does not fit.
  def test_a_request_for_more_memory_than_is_free_does_not_fit
    refute(request("1025MB").fits_within?(request("1GB")))
  end

  # Both amounts have to fit: free memory doesn't make up for free CPUs.
  def test_a_request_that_fits_in_memory_but_not_in_cpus_does_not_fit
    refute(request("1GB", cpus: 4).fits_within?(request("64GB", cpus: 2)))
  end
end
