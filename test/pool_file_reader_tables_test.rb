# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Runs every row of the tables in the pool file page's "Sizes and labels" and "Durations" sections through the reader.
# A row marked "Valid" reads, a row marked "Refused" is refused, and a row that gives a number of megabytes gives it.
class PoolFileReaderTablesTest < Minitest::Test
  include PoolFileReaderHelper

  SETTINGS = %w[budget keep-free share active-for withhold].freeze
  private_constant(:SETTINGS)

  # The text of a pool file that has this one line of the page's tables in it, in the node that takes it.
  def file_with(line)
    case line.split.first
    when "poll" then "repository r url=\"u\" {\n  branch b\n  task t\n  #{line}\n}\n"
    when *SETTINGS then "defaults {\n  #{line}\n}\n"
    else "#{line}\n"
    end
  end

  # The lines that a first cell of a table writes, one for each piece of code in the cell.
  def lines_of(cell)
    cell.scan(/`([^`]+)`/).flatten
  end

  # The number of megabytes that a result cell gives, such as 1,572,864 for "Valid: 1,572,864 MB.", or nil.
  def megabytes_in(result)
    digits = result[/(\d[\d,.]*) MB/, 1]
    digits && Integer(digits.delete(","), 10)
  end

  # The megabytes that the pool file read from a line gives for the setting the line sets.
  def megabytes_of(file, line)
    case line.split.first
    when "budget" then file.defaults.budget.megabytes
    when "keep-free" then file.defaults.keep_free.megabytes
    when "limits" then file.limits.output.megabytes
    else file.defaults.share.megabytes
    end
  end

  # Checks each row of the nth table of this section, with the check for a line that the row says is valid.
  def each_row(heading, nth)
    page_table(heading, nth).each do |written, result|
      lines_of(written).each { |line| yield(line, result) }
    end
  end

  # Pool file reference, "Sizes and labels", first table, and "Durations": each row marked "Refused" is refused, with
  # the pool file's error, and each row marked "Valid" is read.
  def test_each_row_marked_refused_is_refused_and_each_row_marked_valid_is_read
    [["## Sizes and labels", 0], ["## Sizes and labels", 1], ["## Durations", 0]].each do |heading, nth|
      each_row(heading, nth) do |line, result|
        if result.start_with?("Refused")
          assert_raises(Proof::PoolFileError, "#{line}: #{result}") { read(file_with(line)) }
        else
          assert_instance_of(Proof::PoolFile, read(file_with(line)), "#{line}: #{result}")
        end
      end
    end
  end

  # The first table: each row that gives a number of megabytes gives that number.
  def test_each_row_that_gives_megabytes_gives_them
    checked = 0
    each_row("## Sizes and labels", 0) do |line, result|
      next unless result.start_with?("Valid") && megabytes_in(result)

      assert_equal(megabytes_in(result), megabytes_of(read(file_with(line)), line), "#{line}: #{result}")
      checked += 1
    end

    assert_equal(4, checked)
  end

  # The second table: `withhold GPU` is "Valid, and the same as `withhold gpu`".
  def test_the_row_that_says_a_label_is_the_same_as_another_says_so
    page_table("## Sizes and labels", 1).each do |written, result|
      other = result[/the same as `([^`]+)`/, 1]
      next unless other

      assert_equal(read(file_with(other)).defaults, read(file_with(lines_of(written).first)).defaults)
    end
  end

  # The page's tables have the rows these tests expect, so a row the page gains or loses is noticed: seven rows of
  # sizes, four of labels, and eight of durations.
  def test_the_page_has_the_rows_the_tests_run
    counts = [["## Sizes and labels", 0], ["## Sizes and labels", 1], ["## Durations", 0]].map do |heading, nth|
      page_table(heading, nth).size
    end

    assert_equal([7, 4, 8], counts)
  end
end
