# frozen_string_literal: true

require_relative("test_helper")

# Checks a task's entry in the project file.
class TaskEntryTest < Minitest::Test
  # Project file reference, "`task`": "`NAME` is the name you run with `proof
  # run NAME`", and "Task names follow mise's rules, so `test`, `lint:ruby`,
  # and `package-native` are all valid."
  def test_the_names_the_reference_calls_valid_are_kept
    names = %w[test lint:ruby package-native]

    assert_equal(names, names.map { |name| Proof::TaskEntry.new(name:).name })
  end

  # Project file reference, "`task`": "**Without `COMMAND`,** the entry adds
  # Proof's settings to the mise task of the same name, and Proof runs `mise run
  # NAME` on the runner."
  def test_an_entry_without_a_command_has_none
    assert_nil(Proof::TaskEntry.new(name: "test").command)
  end

  # Project file reference, "`task`": "**With `COMMAND`,** the entry defines a
  # task with that command", as `task docs "bundle exec rake rdoc"` does.
  def test_an_entry_with_a_command_keeps_it
    assert_equal("bundle exec rake rdoc", Proof::TaskEntry.new(name: "docs", command: "bundle exec rake rdoc").command)
  end

  # Project file reference, "A complete example": `task test` has `label
  # desktop`, so an entry holds the settings it gives, and an entry that gives
  # none holds none.
  def test_an_entry_holds_its_settings
    settings = Proof::TaskSettings.new(labels: Proof::LabelSet.of("desktop"))

    assert_equal(settings, Proof::TaskEntry.new(name: "test", settings:).settings)
    assert_equal(Proof::TaskSettings.none, Proof::TaskEntry.new(name: "package").settings)
  end

  # Project file reference, "`task`": a `task` node takes a name, and "A
  # name can appear in only one `task` entry", so a name is text.
  def test_a_name_that_is_not_text_is_refused
    [nil, :test, 1, ["test"]].each do |name|
      assert_raises(Proof::InvalidTaskEntryError, name.inspect) { Proof::TaskEntry.new(name:) }
    end
  end

  # Project file reference, "`task`": the command is the text after the name, so
  # a command that is not text is refused.
  def test_a_command_that_is_not_text_is_refused
    [1, :make, ["make"]].each do |command|
      assert_raises(Proof::InvalidTaskEntryError, command.inspect) { Proof::TaskEntry.new(name: "docs", command:) }
    end
  end

  # An entry's settings are the settings of one source, so anything else is refused.
  def test_settings_that_are_not_task_settings_are_refused
    [nil, { cpus: 4 }, "cpus=4"].each do |settings|
      assert_raises(Proof::InvalidTaskEntryError, settings.inspect) { Proof::TaskEntry.new(name: "test", settings:) }
    end
  end

  # The message says what an entry holds and what it got.
  def test_the_message_names_the_value
    error = assert_raises(Proof::InvalidTaskEntryError) { Proof::TaskEntry.new(name: 1) }

    assert_equal("a task entry has a name that is text, not 1", error.message)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidTaskEntryError, :<, Proof::Error)
  end
end
