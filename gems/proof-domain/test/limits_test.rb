# frozen_string_literal: true

require_relative("test_helper")

# Checks the most the server keeps from one run, as the pool file's `limits` node gives it.
class LimitsTest < Minitest::Test
  # The size of this many megabytes.
  def megabytes(count)
    Proof::Size.new(megabytes: count)
  end

  # Pool file reference, "`limits`": the defaults are `output` `"1GB"` and `artifacts` `"16GB"`, counted in 1,024s.
  def test_the_defaults_are_1_gigabyte_of_output_and_16_of_artifacts
    limits = Proof::Limits.new

    assert_equal([megabytes(1024), megabytes(16_384)], [limits.output, limits.artifacts])
  end

  # Pool file reference, "A complete example": `limits output="1GB" artifacts="16GB"` keeps "at most 1 GB of output and
  # 16 GB of artifacts from any one run", and the sizes given are kept as given.
  def test_each_value_is_kept_as_given
    limits = Proof::Limits.new(output: megabytes(512), artifacts: megabytes(2048))

    assert_equal([megabytes(512), megabytes(2048)], [limits.output, limits.artifacts])
  end

  # Pool file reference, "Sizes and labels": `limits output="512mb"` is 512 MB, and the other limit keeps its default.
  def test_a_limit_that_is_not_given_keeps_its_default
    only_output = Proof::Limits.new(output: megabytes(512))
    only_artifacts = Proof::Limits.new(artifacts: megabytes(1))

    assert_equal([megabytes(512), megabytes(16_384)], [only_output.output, only_output.artifacts])
    assert_equal([megabytes(1024), megabytes(1)], [only_artifacts.output, only_artifacts.artifacts])
  end

  # Pool file reference, "`limits`": each is a size, so a number of megabytes, a text, and `nil` are refused.
  def test_a_value_that_is_not_a_size_is_refused
    pairs = %i[output artifacts].product([512, "512MB", nil])

    pairs.each do |member, value|
      assert_raises(Proof::InvalidLimitsError, "#{member} #{value.inspect}") { Proof::Limits.new(member => value) }
    end
  end

  # The message names the limit and says what it got.
  def test_the_message_names_the_limit
    %w[output artifacts].each do |member|
      error = assert_raises(Proof::InvalidLimitsError) { Proof::Limits.new(member.to_sym => "16GB") }

      assert_equal("limits #{member} is a size, not \"16GB\"", error.message)
    end
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidLimitsError, :<, Proof::Error)
  end
end
