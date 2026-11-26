# frozen_string_literal: true

require_relative("test_helper")
require "proof/testing"

# Checks the optional hook of the two-thread tests in `RunsContract`.
class RunsContractHookTest < Minitest::Test
  # A class that gives the contract only what every store's test gives it.
  class Plain
    include Proof::Testing::RunsDurabilityContract

    attr_reader :built

    # A fresh store, kept so a test can compare it.
    def build_runs
      @built = Proof::InMemory::Runs.new
    end
  end

  # A store's test that doesn't define the hook runs the two-thread tests on
  # the store it builds, with the window as narrow as the store makes it.
  def test_the_hook_builds_the_store_build_runs_builds_unless_defined
    plain = Plain.new
    runs = plain.build_runs_pausing_after_reads

    assert_same(plain.built, runs)
  end
end
