# frozen_string_literal: true

require_relative("test_helper")

# Checks what is not a memory size, and what Proof says about it.
class ResourcesSizeRefusedTest < Minitest::Test
  # The start of the message for a memory that isn't a size: the forms that
  # work. What the memory was follows it.
  MEMORY_MESSAGE = "memory is a size: a number, whole or decimal, an optional space, and MB, GB, TB, " \
    "MiB, GiB, or TiB in any case, such as \"512MB\", \"8 GB\", \"1.5gib\", or \"0.5TB\", not "
  private_constant(:MEMORY_MESSAGE)

  # A request of 4 CPUs and the given memory size.
  def request(memory, cpus: 4)
    Proof::Resources.request(cpus:, memory:)
  end

  # Each memory that has to be refused, as the test names it.
  def assert_refused(memories)
    memories.each { |memory| assert_raises(Proof::InvalidResourcesError, memory.inspect) { request(memory) } }
  end

  # Project file reference, "Sizes", table of forms: `"8"`, `"8G"`, and `"8
  # gigabytes"` are "Refused", as are `"1,5GB"`, `".5GB"`, `"5.GB"`, `"1e3MB"`,
  # `"-1GB"`, `"+1GB"`, `"8  GB"`, `" 8GB"`, and `"8GB "`.
  def test_every_form_the_reference_refuses_is_refused
    assert_refused(["8", "8G", "8 gigabytes", "gigabytes", "GB", "", "1,5GB", ".5GB", "5.GB", "1e3MB", "-1GB", "+1GB"])
    assert_refused(["8  GB", " 8GB", "8GB "])
  end

  # Project file reference, "Sizes": the unit is "`MB`, `GB`, or `TB`, or `MiB`,
  # `GiB`, or `TiB`", so no other unit is one.
  def test_a_unit_that_is_not_listed_is_refused
    assert_refused(%w[8KB 8KiB 8PB 8PiB 8B 8M 8Mi 8GBB 8MiBi 8GiGB 8GB8MB 8iB 8MIBB])
  end

  # Project file reference, "Sizes": "The space is none or one space", so no
  # other whitespace is one, and "The number" has no other characters either.
  def test_other_whitespace_and_other_digits_are_refused
    assert_refused(["8\tGB", "8\nGB", "8GB\n", "\n8GB", "8 GB", "٣GB", "1_000MB", "0x10GB", "8.5.1GB"])
  end

  # Project file reference, "Properties": `memory` is "A quoted size", so a
  # number is not one, and "Mistakes Proof catches" lists "a value has the
  # wrong type".
  def test_a_memory_that_is_not_text_is_refused
    assert_refused([nil, 8, 1.5, :"8GB", ["8GB"]])
  end

  # A byte string that isn't valid text, as a command line can hold, is not a
  # size, and raises the resources' error, not Ruby's.
  def test_a_memory_with_invalid_bytes_is_refused
    error = assert_raises(Proof::InvalidResourcesError) { request("8\xFFGB") }

    assert_equal(%(#{MEMORY_MESSAGE}"8\\xFFGB"), error.message)
  end

  # A string in an encoding that isn't ASCII-compatible, such as UTF-16, is
  # valid text but not a size, and raises the resources' error, not Ruby's.
  def test_a_memory_in_an_encoding_that_is_not_ascii_compatible_is_refused
    assert_refused(["8GB".encode(Encoding::UTF_16LE)])
  end

  # Project file reference, "Sizes": "When a size breaks these rules, Proof
  # refuses it with the forms that work", so the message lists the number, the
  # space, and the units, with examples.
  def test_the_message_for_a_memory_names_the_value_and_the_forms_that_work
    error = assert_raises(Proof::InvalidResourcesError) { request("8 gigabytes") }

    assert_equal(%(#{MEMORY_MESSAGE}"8 gigabytes"), error.message)
  end
end
