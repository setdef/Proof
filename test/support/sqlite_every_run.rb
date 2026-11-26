# frozen_string_literal: true

require_relative("../test_helper")
require "proof/testing"

# One run for each way a run can go, which between them hold every kind of fact.
module SqliteEveryRun
  FIXTURES = Proof::Testing::RunFixtures
  AT = FIXTURES::AT
  PLACED = Proof::Run::Placed.new(at: AT, host: "nuc", runner: "nuc-wsl")
  STARTED = Proof::Run::CommandStarted.new(at: AT)
  OUTPUT = Proof::Run::OutputCompleted.new(at: AT, bytes: 48_213)
  EXITED = Proof::Run::CommandEnded.new(at: AT, exit_status: 0)
  SIGNALED = Proof::Run::CommandEnded.new(at: AT, signal: 15)
  CANCELED = Proof::Run::Canceled.new(at: AT)
  OVER_LIMIT = Proof::Run::ArtifactsNotKept.new(at: AT, reason: :over_limit)
  SHORT_OF_SPACE = Proof::Run::ArtifactsNotKept.new(at: AT, reason: :short_of_space)
  QUEUED_FOR_TWO_SYSTEMS = Proof::Run::Queued.new(
    at: AT,
    position: 7,
    os: [Proof::OS.new(name: :macos), Proof::OS.new(name: :linux)],
    labels: Proof::LabelSet.of("kvm", "GPU"),
    resources: Proof::Resources.new(cpus: 4, megabytes: 6144)
  )
  # A run for each of these lists of facts, which follow the fact that the run was queued.
  LATER = [
    [PLACED, STARTED, EXITED, OUTPUT, Proof::Run::ArtifactsKept.new(at: AT), Proof::Run::Succeeded.new(at: AT)],
    [Proof::Run::CancelAsked.new(at: AT), PLACED, STARTED, SIGNALED, OUTPUT, OVER_LIMIT, CANCELED],
    [PLACED, SHORT_OF_SPACE, Proof::Run::Failed.new(at: AT)],
    [PLACED, STARTED, Proof::Run::TimedOut.new(at: AT)],
    [PLACED, STARTED, Proof::Run::OutOfMemory.new(at: AT)],
    [PLACED, Proof::Run::Lost.new(at: AT), Proof::Run::ProcessesEnded.new(at: AT)],
  ].freeze
  RUNS = [
    *LATER.each_with_index.map { |later, index| FIXTURES.run(id: "k7q2#{index}", position: index + 1, later:) },
    Proof::Run.new(id: FIXTURES.id("k1n6s"), facts: [QUEUED_FOR_TWO_SYSTEMS]),
  ].freeze
  public_constant(:RUNS)
  private_constant(:FIXTURES, :AT, :PLACED, :STARTED, :OUTPUT)
  private_constant(:EXITED, :SIGNALED, :CANCELED, :OVER_LIMIT, :SHORT_OF_SPACE, :QUEUED_FOR_TWO_SYSTEMS, :LATER)
end
