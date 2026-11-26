# frozen_string_literal: true

require_relative("test_helper")

# Checks the project file: its `defaults` and its task entries.
class ProjectFileTest < Minitest::Test
  # An entry with this name and no settings.
  def entry(name)
    Proof::TaskEntry.new(name:)
  end

  # Project file reference, "The file is optional. Without it, `proof run NAME`
  # runs `mise run NAME` with Proof's built-in defaults", so no file gives no
  # defaults and no entries.
  def test_a_project_with_no_file_has_no_defaults_and_no_entries
    none = Proof::ProjectFile.none

    assert_equal(Proof::TaskSettings.none, none.defaults)
    assert_empty(none.entries)
  end

  # Project file reference, "`defaults`": "A file has at most one `defaults`
  # node", so a file holds one set of defaults.
  def test_a_file_holds_its_defaults
    defaults = Proof::TaskSettings.new(cpus: 4)

    assert_equal(defaults, Proof::ProjectFile.new(defaults:).defaults)
  end

  # Project file reference, "A complete example": the file has the tasks
  # `test`, `package`, and `docs`, so a file holds its entries in the order written.
  def test_a_file_holds_its_entries_in_order
    file = Proof::ProjectFile.new(entries: [entry("test"), entry("package"), entry("docs")])

    assert_equal(%w[test package docs], file.entries.map(&:name))
  end

  # Project file reference, "`task`": "`NAME` is the name you run with `proof
  # run NAME`", so an entry is found by its name.
  def test_an_entry_is_found_by_its_name
    docs = entry("docs")
    file = Proof::ProjectFile.new(entries: [entry("test"), docs])

    assert_same(docs, file.entry_named("docs"))
  end

  # Project file reference, "Tasks without a project file": "Fails on the
  # runner: mise has no `docs` task", so a name with no entry has none.
  def test_a_name_with_no_entry_has_none
    assert_nil(Proof::ProjectFile.new(entries: [entry("test")]).entry_named("docs"))
    assert_nil(Proof::ProjectFile.none.entry_named("test"))
  end

  # Project file reference, "Mistakes Proof catches": "two `task` entries have
  # the same name", and "`task`": "A name can appear in only one `task` entry."
  def test_two_entries_with_one_name_are_refused
    assert_raises(Proof::InvalidProjectFileError) { Proof::ProjectFile.new(entries: [entry("test"), entry("docs"), entry("test")]) }
  end

  # Project file reference, "`task`": "A name can appear in only one `task`
  # entry", whatever else the two entries differ in.
  def test_two_entries_with_one_name_are_refused_though_their_commands_differ
    entries = [Proof::TaskEntry.new(name: "docs", command: "a"), Proof::TaskEntry.new(name: "docs", command: "b")]

    assert_raises(Proof::InvalidProjectFileError) { Proof::ProjectFile.new(entries:) }
  end

  # Project file reference, "`task`": names are compared as written, so `test`
  # and `Test` are two tasks, as mise's task names are.
  def test_names_that_differ_in_case_are_two_tasks
    assert_equal(2, Proof::ProjectFile.new(entries: [entry("test"), entry("Test")]).entries.size)
  end

  # The message says which name and what works.
  def test_the_message_for_a_repeated_name_names_it_and_says_what_works
    error = assert_raises(Proof::InvalidProjectFileError) { Proof::ProjectFile.new(entries: [entry("test"), entry("test")]) }

    assert_equal(
      'two task entries are named "test". A name appears in only one task entry, so merge them into one.',
      error.message
    )
  end

  # Project file reference, "`defaults`": defaults "take the same properties and
  # children as a `task`", so they are task settings, and entries are task entries.
  def test_defaults_and_entries_of_another_kind_are_refused
    [{ cpus: 4 }, nil].each do |defaults|
      assert_raises(Proof::InvalidProjectFileError, defaults.inspect) { Proof::ProjectFile.new(defaults:) }
    end
    [["test"], nil, "test"].each do |entries|
      assert_raises(Proof::InvalidProjectFileError, entries.inspect) { Proof::ProjectFile.new(entries:) }
    end
  end

  # The message says what the defaults are, and what they were.
  def test_the_message_for_defaults_names_the_value
    error = assert_raises(Proof::InvalidProjectFileError) { Proof::ProjectFile.new(defaults: 1) }

    assert_equal("a project file's defaults are task settings, not 1", error.message)
  end

  # The message says what the entries are, and what they were.
  def test_the_message_for_entries_names_the_value
    error = assert_raises(Proof::InvalidProjectFileError) { Proof::ProjectFile.new(entries: 1) }

    assert_equal("a project file's entries are a list of task entries, not 1", error.message)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidProjectFileError, :<, Proof::Error)
  end
end
