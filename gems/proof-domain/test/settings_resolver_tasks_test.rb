# frozen_string_literal: true

require_relative("several_tasks_helper")
require_relative("test_helper")

# Checks the settings of a run of several tasks, which have to suit all of them.
class SettingsResolverTasksTest < Minitest::Test
  include SeveralTasksHelper

  # Project file reference, "Several tasks on one command line", table: `os` is
  # "The operating systems every one of them works on".
  def test_the_operating_systems_are_those_every_task_works_on
    assert_equal(["macos"], os_names(resolve(several, "lint", "test").settings.os))
  end

  # Project file reference, "Several tasks on one command line", table: `os` is
  # "every one of them", so a task that works anywhere narrows nothing.
  def test_a_task_that_works_anywhere_narrows_nothing
    assert_equal(%w[linux macos], os_names(resolve(several, "lint", "package").settings.os))
  end

  # Project file reference, "Several tasks on one command line", table: `label`
  # is "Every label any of them needs".
  def test_the_labels_are_every_label_any_task_needs
    assert_equal(%w[desktop kvm], label_names(resolve(several, "lint", "test", "package").settings.labels))
  end

  # Project file reference, "Several tasks on one command line", table: `cpus`,
  # `memory`, `timeout` are "The largest of their values".
  def test_cpus_memory_and_time_limit_are_the_largest
    settings = resolve(several, "lint", "test", "package").settings

    assert_equal([8, 16_384, 7200], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
  end

  # Project file reference, "Several tasks on one command line", table: the
  # largest of each, taken one by one, so each comes from a different task.
  def test_the_largest_values_may_come_from_different_tasks
    settings = resolve(several, "lint", "test").settings

    assert_equal([8, 2048, 600], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
  end

  # Project file reference, "Several tasks on one command line", table:
  # `artifact` and `cache` are "All of them".
  def test_the_artifacts_and_caches_are_all_of_them
    settings = resolve(several, "lint", "test", "package").settings

    assert_equal([%w[a/* b/*], %w[c1 c2]], [path_names(settings.artifacts), path_names(settings.caches)])
  end

  # Project file reference, "Several tasks on one command line": "`proof run
  # lint ::: test` runs both tasks in one run", each with its own command.
  def test_each_task_keeps_its_own_command
    file = Proof::ProjectFile.new(entries: [entry("lint", "rubocop"), entry("test")])

    assert_equal(named(%w[lint rubocop], ["test", nil]), resolve(file, "lint", "test").commands)
  end

  # Project file reference, "Several tasks on one command line": "When the
  # tasks have no operating system in common, Proof refuses the run before
  # sending anything".
  def test_tasks_with_no_operating_system_in_common_are_refused
    file = Proof::ProjectFile.new(entries: [entry("lint", os: ["linux"]), entry("ios", os: ["macos"])])

    assert_raises(Proof::NoSharedOSError) { resolve(file, "lint", "ios") }
  end

  # Project file reference, "Several tasks on one command line": Proof "lists
  # each task's operating systems", in the order of the command line.
  def test_the_refusal_lists_each_tasks_operating_systems
    file = Proof::ProjectFile.new(entries: [entry("lint", os: ["linux"]), entry("ios", os: %w[windows macos])])
    error = assert_raises(Proof::NoSharedOSError) { resolve(file, "lint", "ios") }

    assert_equal(
      "no operating system is common to these tasks: lint works on linux; ios works on macos, windows. " \
        "Run them with separate commands, or name one operating system with --os.",
      error.message
    )
  end

  # Project file reference, "Several tasks on one command line": the refusal
  # lists each task, and a task that works anywhere works on all three.
  def test_the_refusal_lists_all_three_operating_systems_for_a_task_that_works_anywhere
    file = Proof::ProjectFile.new(entries: [entry("a", os: ["linux"]), entry("b", os: ["macos"])])
    error = assert_raises(Proof::NoSharedOSError) { resolve(file, "a", "b", "anywhere") }

    assert_match(/; anywhere works on linux, macos, windows\./, error.message)
  end

  # Project file reference, "How values combine": "`--os` replaces both", so a
  # flag's `os` replaces every task's, and tasks that share none then share the flag's.
  def test_a_flags_os_replaces_every_tasks_os
    file = Proof::ProjectFile.new(entries: [entry("lint", os: ["linux"]), entry("ios", os: ["macos"])])

    assert_equal(["windows"], os_names(resolve(file, "lint", "ios", os: ["windows"]).settings.os))
  end

  # Project file reference, "Several tasks on one command line": a name with no
  # entry works on whatever the defaults say, and so joins the others' settings.
  def test_a_task_with_no_entry_joins_the_others_with_the_defaults
    file = Proof::ProjectFile.new(defaults: given(cpus: 6), entries: [entry("test", os: ["linux"], cpus: 2)])
    settings = resolve(file, "test", "nothing").settings

    assert_equal([6, ["linux"]], [settings.cpus, os_names(settings.os)])
  end

  # Project file reference, "Several tasks on one command line": the settings of
  # one task are those of a run of that task alone, so one name resolves to
  # what its entry and the defaults give.
  def test_one_task_resolves_to_its_own_settings
    settings = resolve(several, "test").settings

    assert_equal([8, 1024, 300], [settings.cpus, settings.megabytes, settings.time_limit.seconds])
    assert_equal(%w[macos windows], os_names(settings.os))
  end

  # Project file reference, "Several tasks on one command line": `:::` starts the
  # next task, and a task named twice is one task, with one command.
  def test_a_task_named_twice_is_one_task
    file = Proof::ProjectFile.new(entries: [entry("test", "make test", cpus: 3)])
    run = resolve(file, "test", "test")

    assert_equal([named(["test", "make test"]), 3], [run.commands, run.settings.cpus])
  end

  # The names of tasks may be a `Set` as well as an `Array`, in the order they were added.
  def test_task_names_may_be_a_set
    resolver = Proof::SettingsResolver.new(project_file: several, flags: Proof::TaskSettings.none)

    assert_equal(%w[lint test], resolver.resolve(Set["lint", "test"]).commands.keys)
  end

  # A run has at least one task, because `proof run` needs a task name.
  def test_a_run_with_no_task_is_refused
    assert_raises(Proof::InvalidRunSettingsError) { resolve(several) }
  end

  # The message says what a run needs.
  def test_the_message_for_no_task_says_what_a_run_needs
    error = assert_raises(Proof::InvalidRunSettingsError) { resolve(several) }

    assert_equal("a run has one or more task names, not []", error.message)
  end

  # A task name is text, as an entry's is.
  def test_a_task_name_that_is_not_text_is_refused
    [nil, :test, 1].each do |name|
      assert_raises(Proof::InvalidRunSettingsError, name.inspect) do
        Proof::SettingsResolver.new(project_file: several, flags: Proof::TaskSettings.none).resolve([name])
      end
    end
  end

  # The names of tasks are a list, as a command line gives them.
  def test_task_names_that_are_not_a_list_are_refused
    resolver = Proof::SettingsResolver.new(project_file: several, flags: Proof::TaskSettings.none)

    assert_raises(Proof::InvalidRunSettingsError) { resolver.resolve("test") }
  end

  # The resolver reads a project file and flags, so it refuses anything else.
  def test_a_project_file_or_flags_of_another_kind_are_refused
    assert_raises(Proof::InvalidRunSettingsError) { Proof::SettingsResolver.new(project_file: nil, flags: Proof::TaskSettings.none) }
    assert_raises(Proof::InvalidRunSettingsError) { Proof::SettingsResolver.new(project_file: several, flags: nil) }
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_errors_are_proof_errors
    assert_operator(Proof::NoSharedOSError, :<, Proof::Error)
    assert_operator(Proof::InvalidRunSettingsError, :<, Proof::Error)
  end
end
