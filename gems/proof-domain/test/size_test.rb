# frozen_string_literal: true

require_relative("test_helper")

# Checks a size, read as the pool file writes the budget, the free space a host keeps, and the limits.
class SizeTest < Minitest::Test
  # The megabytes of a size written as this text.
  def megabytes(text)
    Proof::Size.read(text, name: "budget").megabytes
  end

  # Pool file reference, "Sizes and labels", first table: each row that the page marks valid reads as the megabytes it
  # gives. `budget "1.5TB"` is 1,572,864 MB, `keep-free "50 GiB"` is 51,200 MB, `limits output="512mb"` is 512 MB, and
  # `memory="0.1GB"` is 103 MB, rounded up from 102.4 MB.
  def test_each_valid_size_in_the_page_table_is_read_into_megabytes
    assert_equal([1_572_864, 51_200, 512, 103], ["1.5TB", "50 GiB", "512mb", "0.1GB"].map { |text| megabytes(text) })
  end

  # Pool file reference, `defaults` and the complete example: the sizes the page writes are `"100GB"`, `"400GB"`,
  # `"250GB"`, `"25GB"`, `"1GB"`, and `"16GB"`, counted in 1,024s.
  def test_the_sizes_of_the_complete_example_are_counted_in_1024s
    sizes = %w[100GB 400GB 250GB 25GB 1GB 16GB].map { |text| megabytes(text) }

    assert_equal([102_400, 409_600, 256_000, 25_600, 1024, 16_384], sizes)
  end

  # Project file reference, "Sizes", which the pool file reference points to: `"0GB"` is "Valid: a host's share can
  # keep nothing free."
  def test_zero_is_a_size
    assert_equal(0, megabytes("0GB"))
  end

  # The same section: "`MB` and `MiB` are the same unit", and a unit is in any case.
  def test_a_size_is_one_size_however_it_is_written
    sizes = ["8GB", "8 GB", "8gb", "8GiB"].map { |text| megabytes(text) }

    assert_equal([8192] * 4, sizes)
  end
end
