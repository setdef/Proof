# frozen_string_literal: true

require_relative("support/run_facts")
require_relative("test_helper")

# Checks the fact that a run's command ended.
class RunCommandEndTest < Minitest::Test
  include RunFacts

  # Runner design, "A run's end": "The status of a run must come from the
  # command", so the fact keeps the exit status as the command gave it.
  def test_a_command_that_exited_keeps_its_status
    fact = exited(3)

    assert_equal(3, fact.exit_status)
    assert_nil(fact.signal)
    refute_predicate(fact, :exited_zero?)
  end

  # Only an exit status of 0 is a command that exited with 0.
  def test_only_status_zero_is_exited_zero
    assert_predicate(exited(0), :exited_zero?)
    refute_predicate(signaled(9), :exited_zero?)
  end

  # A command a signal ended has no exit status, and the fact says which signal.
  def test_a_command_that_a_signal_ended_keeps_the_signal
    fact = signaled(15)

    assert_equal(15, fact.signal)
    assert_nil(fact.exit_status)
  end

  # A command ends one way: with an exit status, or by a signal.
  def test_a_command_end_with_both_an_exit_status_and_a_signal_is_refused
    error = assert_raises(Proof::InvalidFactError) { Proof::Run::CommandEnded.new(at: AT, exit_status: 137, signal: 9) }

    assert_equal("a command ends with an exit status or a signal, not exit_status=137 signal=9", error.message)
  end

  # A command that ended has one or the other.
  def test_a_command_end_with_neither_an_exit_status_nor_a_signal_is_refused
    error = assert_raises(Proof::InvalidFactError) { Proof::Run::CommandEnded.new(at: AT) }

    assert_equal("a command ends with an exit status or a signal, not exit_status=nil signal=nil", error.message)
  end

  # Windows gives a process a 32-bit exit code, so the largest is 4,294,967,295.
  def test_an_exit_status_runs_from_zero_to_the_largest_windows_exit_code
    assert_equal(4_294_967_295, exited(4_294_967_295).exit_status)
    [-1, 4_294_967_296, 1.0].each do |status|
      error = assert_raises(Proof::InvalidFactError) { exited(status) }

      assert_equal(format("an exit status is a whole number from 0 to 4294967295, not %p", status), error.message)
    end
  end

  # A signal is a whole number from 1.
  def test_a_signal_below_one_is_refused
    assert_equal(1, signaled(1).signal)
    error = assert_raises(Proof::InvalidFactError) { signaled(0) }

    assert_equal("a signal is a whole number from 1, not 0", error.message)
  end
end
