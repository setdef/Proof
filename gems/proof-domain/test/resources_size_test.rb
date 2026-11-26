# frozen_string_literal: true

require_relative("test_helper")

# Checks how a memory size is read into megabytes.
class ResourcesSizeTest < Minitest::Test
  # A request of 4 CPUs and the given memory size.
  def request(memory, cpus: 4)
    Proof::Resources.request(cpus:, memory:)
  end

  # Each size, with the megabytes it reads as.
  def assert_megabytes(sizes)
    sizes.each { |memory, megabytes| assert_equal(megabytes, request(memory).megabytes, memory) }
  end

  # Project file reference, "Properties": `memory` is "A quoted size, such as
  # `"512MB"`, `"8GB"`, or `"1.5 GiB"`", and "Sizes" lists `"512MB"` as 512 MB.
  def test_a_size_in_megabytes_is_read_as_megabytes
    assert_megabytes([["512MB", 512]])
  end

  # Project file reference, "Sizes": "`1GB` is 1,024 MB", and `"8GB"` is
  # 8,192 MB in the table.
  def test_a_size_in_gigabytes_counts_1024_megabytes_to_the_gigabyte
    assert_megabytes([["1GB", 1024], ["8GB", 8192]])
  end

  # Project file reference, "Sizes": "`1TB` is 1,048,576 MB", and `"1TB"` is
  # 1,048,576 MB in the table.
  def test_a_size_in_terabytes_counts_1024_gigabytes_to_the_terabyte
    assert_megabytes([["1TB", 1_048_576], ["2TB", 2_097_152]])
  end

  # Project file reference, "Sizes": "`1GB` is 1,024 MB".
  def test_a_gigabyte_and_1024_megabytes_are_one_request
    assert_equal(request("1GB"), request("1024MB"))
  end

  # Project file reference, "Sizes": "`MB` and `MiB` are the same unit", and
  # so are `GB` and `GiB`, and `TB` and `TiB`.
  def test_a_unit_with_an_i_is_the_same_unit_as_the_one_without
    assert_equal(request("512MB"), request("512MiB"))
    assert_equal(request("8GB"), request("8GiB"))
    assert_equal(request("2TB"), request("2TiB"))
  end

  # Project file reference, "Sizes": "The unit is `MB`, `GB`, or `TB`, or `MiB`,
  # `GiB`, or `TiB`, in any case, so `gb` and `Gb` work."
  def test_a_unit_is_read_in_any_case
    %w[8GB 8gb 8Gb 8gB 8GIB 8gib 8giB 8GiB 8Gib].each do |memory|
      assert_equal(8192, request(memory).megabytes, memory)
    end
    assert_megabytes([["512mb", 512], ["1tIb", 1_048_576], ["3mIB", 3]])
  end

  # Project file reference, "Sizes": "The space is none or one space, so `8GB`
  # and `8 GB` are the same size."
  def test_one_space_between_the_number_and_the_unit_makes_no_difference
    assert_equal(request("8GB"), request("8 GB"))
    assert_equal(request("1.5GiB"), request("1.5 gib"))
  end

  # Project file reference, "Sizes": "The number is whole, such as `8`, or
  # decimal with digits on both sides of the point, such as `1.5`", and
  # `"1.5GB"` is 1,536 MB in the table.
  def test_a_decimal_number_is_a_size
    assert_megabytes([["1.5GB", 1536], ["0.25GB", 256], ["1.5TB", 1_572_864], ["1.0MB", 1]])
  end

  # Project file reference, "Sizes": "A size that isn't a whole number of
  # megabytes rounds up to the next whole megabyte", and `"0.1GB"` is 103 MB
  # in the table, rounded up from 102.4 MB.
  def test_a_size_that_is_not_a_whole_number_of_megabytes_rounds_up
    assert_megabytes([["0.1GB", 103], ["1.1MB", 2], ["0.0001MB", 1]])
  end

  # Project file reference, "Sizes": a size "rounds up to the next whole
  # megabyte", so a size that is a whole number of megabytes doesn't round,
  # whatever digits it is written with.
  def test_a_size_that_is_a_whole_number_of_megabytes_does_not_round_up
    assert_megabytes([["1.50GB", 1536], ["1.00GB", 1024], ["5.000MB", 5]])
  end

  # Project file reference, "Sizes": a size "rounds up to the next whole
  # megabyte", with no error from adding fractions, so it is exact for a
  # decimal that has no exact form as a binary fraction.
  def test_rounding_is_exact_for_decimals_a_binary_float_cannot_hold
    assert_megabytes([["1.000001TB", 1_048_578], ["2.0000000000000001MB", 3], ["7.0000000000000000MB", 7]])
  end

  # Project file reference, "Sizes": the table lists `"0GB"` as 0 MB, "Valid: a
  # host's share can keep nothing free", and pool file reference, "Properties" of
  # a host: "With a share of `cpus=0 memory="0GB"`, Proof keeps nothing free ...
  # Proof accepts it".
  def test_a_size_of_zero_is_a_size
    assert_megabytes([["0GB", 0], ["0.0MB", 0]])
  end
end
