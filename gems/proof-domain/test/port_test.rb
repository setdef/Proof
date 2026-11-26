# frozen_string_literal: true

require_relative("test_helper")

# Checks the port the server listens on, and the rule that a port is a whole number from 1 to 65535.
class PortTest < Minitest::Test
  # Pool file reference, "`server`": `port` is "A port number", the TCP port, so a whole number from 1 to 65535 is one,
  # from the first port to the last.
  def test_a_whole_number_from_1_to_65535_is_a_port
    assert_equal([1, 80, 7443, 65_535], [1, 80, 7443, 65_535].map { |number| Proof::Port.new(number:).number })
  end

  # The same row: a number below 1 or above 65535, a decimal, text, `nil`, and `true` are not port numbers.
  def test_a_value_that_is_not_a_port_number_is_refused
    [0, -1, 65_536, 70_000, 1.5, "7443", nil, true].each do |number|
      assert_raises(Proof::InvalidPortError, number.inspect) { Proof::Port.new(number:) }
    end
  end

  # Pool file reference, "What happens when the file has a mistake": the message says what a port is, and what it
  # got, and it names the server's port, because that is the port a file gives.
  def test_the_message_says_what_a_port_is_and_what_it_got
    assert_equal("the server's port is a whole number from 1 to 65535, not 70000", refusal(70_000))
    assert_equal("the server's port is a whole number from 1 to 65535, not \"7443\"", refusal("7443"))
  end

  # A port is equal to a port with the same number, and to nothing else.
  def test_a_port_is_equal_to_a_port_of_the_same_number
    assert_equal(Proof::Port.new(number: 80), Proof::Port.new(number: 80))
    refute_equal(Proof::Port.new(number: 80), Proof::Port.new(number: 81))
    refute_equal(Proof::Port.new(number: 80), 80)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidPortError, :<, Proof::Error)
  end

  private def refusal(number)
    error = assert_raises(Proof::InvalidPortError) { Proof::Port.new(number:) }
    error.message
  end
end
