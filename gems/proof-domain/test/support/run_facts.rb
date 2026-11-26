# frozen_string_literal: true

require_relative("../test_helper")

# Builders for a run's facts, with plain values a test can override, so a test
# shows only the value it checks.
module RunFacts
  AT = Time.utc(2026, 11, 25, 3, 36)
  ID = Proof::RunId.parse("20261125-0336-m3d8q")
  public_constant(:AT, :ID)

  # The fact that a run was queued, for Linux with 2 CPUs and 4 GB by default.
  def queued(position: 1, os: %i[linux], labels: [], cpus: 2, memory: "4GB")
    Proof::Run::Queued.new(
      at: AT,
      position:,
      os: os.map { |name| Proof::OS.new(name:) },
      labels: Proof::LabelSet.of(*labels),
      resources: Proof::Resources.request(cpus:, memory:)
    )
  end

  # The fact that a run was placed on a runner of a host.
  def placed(host: "nuc", runner: "nuc-linux")
    Proof::Run::Placed.new(at: AT, host:, runner:)
  end

  # The fact that the command started.
  def started
    Proof::Run::CommandStarted.new(at: AT)
  end

  # The fact that the command exited with a status, 0 by default.
  def exited(status = 0)
    Proof::Run::CommandEnded.new(at: AT, exit_status: status)
  end

  # The fact that a signal ended the command.
  def signaled(signal = 9)
    Proof::Run::CommandEnded.new(at: AT, signal:)
  end

  # The fact that the whole output arrived.
  def output(bytes = 10)
    Proof::Run::OutputCompleted.new(at: AT, bytes:)
  end

  # The fact that the artifacts were kept.
  def kept
    Proof::Run::ArtifactsKept.new(at: AT)
  end

  # The fact that the artifacts weren't kept.
  def not_kept(reason = :no_match)
    Proof::Run::ArtifactsNotKept.new(at: AT, reason:)
  end

  # The fact that someone asked to cancel the run.
  def cancel
    Proof::Run::CancelAsked.new(at: AT)
  end

  # The fact of a final state, named as the glossary names it.
  def ended(state)
    Proof::Run::FINAL_STATES.key(state).new(at: AT)
  end

  # The fact that a lost run's processes ended.
  def processes_ended
    Proof::Run::ProcessesEnded.new(at: AT)
  end

  # A run with these facts. Minitest::Test has a method named run, so this one
  # has another name.
  def run_of(*facts, id: ID)
    Proof::Run.new(id:, facts:)
  end

  # The facts of a run that ran its command to an exit status, with its whole
  # output, ready for its artifacts.
  def ran(status = 0)
    [queued, placed, started, exited(status), output]
  end

  # Asserts that a run of these facts raises with the message of +rule+.
  def assert_breaks(rule, *facts)
    error = assert_raises(Proof::InvalidRunError) { run_of(*facts) }

    assert_equal("run 20261125-0336-m3d8q breaks a rule: #{rule}", error.message)
  end
end
