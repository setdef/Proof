# frozen_string_literal: true

require_relative("test_helper")

# Checks the CPUs and memory a task requests.
class ResourcesTest < Minitest::Test
  # A request of 4 CPUs and the given memory size.
  def request(memory, cpus: 4)
    Proof::Resources.request(cpus:, memory:)
  end

  # Project file reference, "Properties": the built-in default is `2` CPUs and
  # `"4GB"`, and a task requests the CPUs it is given.
  def test_the_cpus_and_memory_are_kept
    resources = request("4GB", cpus: 2)

    assert_equal([2, 4096], [resources.cpus, resources.megabytes])
  end

  # Project file reference, "Properties": `cpus` is "A whole number from 1".
  def test_cpus_are_a_whole_number_from_one
    assert_equal(1, request("1GB", cpus: 1).cpus)
    assert_equal(64, request("1GB", cpus: 64).cpus)
  end

  # Project file reference, "Properties": `cpus` is "A whole number from 1",
  # so 0 and the negative numbers are not.
  def test_cpus_below_1_are_refused
    [0, -1].each do |cpus|
      assert_raises(Proof::InvalidResourcesError) { request("1GB", cpus:) }
    end
  end

  # Project file reference, "Mistakes Proof catches": "a value has the wrong
  # type, such as `cpus="four"`", and `cpus` is "A whole number".
  def test_cpus_that_are_not_a_whole_number_are_refused
    ["four", "4", 1.5, 4.0, nil, [4]].each do |cpus|
      assert_raises(Proof::InvalidResourcesError) { request("1GB", cpus:) }
    end
  end

  # The message says what cpus are and what it got.
  def test_the_message_for_cpus_names_the_value
    error = assert_raises(Proof::InvalidResourcesError) { request("1GB", cpus: 0) }

    assert_equal("cpus is a whole number from 1, not 0", error.message)
  end

  # Pool file reference, "Properties" of a host: "With a share of `cpus=0
  # memory="0GB"`, Proof keeps nothing free ... Proof accepts it", and a host
  # whose CPUs are all in use has 0 free, so resources built directly hold 0 CPUs.
  def test_resources_built_directly_hold_zero_cpus
    resources = Proof::Resources.new(cpus: 0, megabytes: 0)

    assert_equal([0, 0], [resources.cpus, resources.megabytes])
  end

  # Resources built directly hold a whole number of CPUs from 0, so a
  # negative number, a fraction, and text are refused.
  def test_cpus_built_directly_below_zero_or_not_whole_are_refused
    [-1, 1.5, "1", nil].each do |cpus|
      assert_raises(Proof::InvalidResourcesError) { Proof::Resources.new(cpus:, megabytes: 0) }
    end
  end

  # The message says what cpus are, from 0, and what they got.
  def test_the_message_for_cpus_built_directly_names_the_value
    error = assert_raises(Proof::InvalidResourcesError) { Proof::Resources.new(cpus: -1, megabytes: 0) }

    assert_equal("cpus is a whole number from 0, not -1", error.message)
  end

  # Project file reference, "Properties": `cpus` is "A whole number from 1",
  # and Pool file reference, "Properties" of a host, accepts `cpus=0`, so only
  # a request holds the floor of 1.
  def test_a_request_for_zero_cpus_is_refused_though_zero_cpus_can_be_free
    assert_raises(Proof::InvalidResourcesError) { request("0GB", cpus: 0) }
    assert_equal(0, Proof::Resources.new(cpus: 0, megabytes: 0).cpus)
  end

  # Megabytes, built directly, are a whole number from 0, as a size is.
  def test_megabytes_are_a_whole_number_from_zero
    assert_equal(0, Proof::Resources.new(cpus: 1, megabytes: 0).megabytes)
    [-1, 1.5, "512", nil].each do |megabytes|
      assert_raises(Proof::InvalidResourcesError) { Proof::Resources.new(cpus: 1, megabytes:) }
    end
  end

  # The message says what megabytes are and what it got.
  def test_the_message_for_megabytes_names_the_value
    error = assert_raises(Proof::InvalidResourcesError) { Proof::Resources.new(cpus: 1, megabytes: -1) }

    assert_equal("megabytes is a whole number from 0, not -1", error.message)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidResourcesError, :<, Proof::Error)
  end
end
