# frozen_string_literal: true

require_relative("project_file_helper")
require_relative("test_helper")

# Checks what a run gets: every setting filled in, and each task's command.
class RunSettingsTest < Minitest::Test
  include ProjectFileHelper

  # Settings that give every setting.
  def full
    given(os: ["linux"], label: [], cpus: 2, memory: "4GB", timeout: "60m", artifact: [], cache: [])
  end

  # Project file reference, "How values combine": a run's value comes from the
  # first source that has it, ending with "Proof's built-in defaults", so no
  # setting of a run is missing.
  def test_a_run_holds_every_setting_and_the_commands
    run = Proof::RunSettings.new(settings: full, commands: named(["test", nil]))

    assert_equal([full, named(["test", nil])], [run.settings, run.commands])
  end

  # A run's settings are all given, so a setting left out is refused.
  def test_a_setting_that_is_not_given_is_refused
    %i[os labels cpus megabytes time_limit artifacts caches].each do |member|
      settings = Proof::TaskSettings.new(**full.to_h, member => nil)

      assert_raises(Proof::InvalidRunSettingsError, member.to_s) { Proof::RunSettings.new(settings:, commands: named(["test", nil])) }
    end
  end

  # The message names the setting that is missing.
  def test_the_message_names_the_missing_setting
    settings = Proof::TaskSettings.new(**full.to_h, cpus: nil)
    error = assert_raises(Proof::InvalidRunSettingsError) { Proof::RunSettings.new(settings:, commands: named(["test", nil])) }

    assert_equal("a run has every setting, and cpus is missing", error.message)
  end

  # A run's settings are `Proof::TaskSettings`.
  def test_settings_of_another_kind_are_refused
    assert_raises(Proof::InvalidRunSettingsError) { Proof::RunSettings.new(settings: { cpus: 2 }, commands: named(["test", nil])) }
  end

  # Project file reference, "`task`": a task runs `mise run NAME` or its command,
  # so each task name has a command that is text or none, and a run has a task.
  def test_commands_that_are_not_names_with_text_or_none_are_refused
    [{}, nil, [["test", nil]], named(["test", 1]), { test: nil }, named(["test", :make])].each do |commands|
      assert_raises(Proof::InvalidRunSettingsError, commands.inspect) { Proof::RunSettings.new(settings: full, commands:) }
    end
  end

  # The commands are frozen with the run, so later changes can't alter the run.
  def test_the_commands_are_frozen
    commands = named(["test", nil])
    run = Proof::RunSettings.new(settings: full, commands:)
    commands["other"] = "x"

    assert_equal([named(["test", nil]), true], [run.commands, run.commands.frozen?])
  end

  # The message says what the commands are, and what they were.
  def test_the_message_for_commands_names_the_value
    error = assert_raises(Proof::InvalidRunSettingsError) { Proof::RunSettings.new(settings: full, commands: {}) }

    assert_equal("a run has a command or none for each task name, not {}", error.message)
  end
end
