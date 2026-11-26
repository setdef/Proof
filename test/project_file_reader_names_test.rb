# frozen_string_literal: true

require_relative("support/project_file_reader_helper")

# Checks the mistakes in names and paths, a repeated property, and text that isn't KDL 2.
class ProjectFileReaderNamesTest < Minitest::Test
  include ProjectFileReaderHelper

  # The size rule's table: "`8GB`, unquoted: Refused. KDL reads `8GB` as the number 8 followed by `GB`", so the
  # refusal is of the text, with the quotes that work.
  def test_an_unquoted_size_is_refused_as_text_that_is_not_kdl
    assert_refused(
      "task a\ntask package memory=8GB\n",
      2,
      "this is not valid KDL 2: unexpected IDENT \"GB\" at column 22. " \
        "If a value starts with a digit and continues with letters, put it in quotes, as in memory=\"8GB\""
    )
  end

  # Project file reference, "Mistakes Proof catches": "two `task` entries have the same name", and the refusal
  # names the second entry's line.
  def test_two_entries_with_one_name_are_refused_at_the_second
    assert_refused(
      "task test\ntask lint\n\ntask test cpus=4\n",
      4,
      "two task entries are named \"test\", and the first is on line 1. " \
        "A name appears in only one task entry, so merge them into one"
    )
  end

  # The same bullet: names are compared as written, so `test` and `Test` are two tasks.
  def test_names_that_differ_in_case_are_two_tasks
    assert_equal(%w[test Test], read("task test\ntask Test\n").entries.map(&:name))
  end

  # The same bullet, for a name written in quotes and a name written bare, which are one name.
  def test_a_name_in_quotes_is_the_name_without_them
    assert_refused(
      "task test\ntask \"test\"\n",
      2,
      "two task entries are named \"test\", and the first is on line 1. " \
        "A name appears in only one task entry, so merge them into one"
    )
  end

  # Project file reference, "Mistakes Proof catches": "a `cache` or `artifact` path starts with `/`".
  def test_a_path_that_starts_with_a_slash_is_refused
    assert_refused(
      "task a {\n  artifact \"pkg/*.gem\" \"/etc/passwd\"\n}\n",
      2,
      domain_said(Proof::InvalidPathPatternError) { Proof::PathPattern.new(path: "/etc/passwd") }
    )
    assert_refused(
      "defaults {\n  cache \"/tmp\"\n}\n", 2, domain_said(Proof::InvalidPathPatternError) { Proof::PathPattern.new(path: "/tmp") }
    )
  end

  # The same bullet: a path that "contains `..`".
  def test_a_path_that_contains_two_dots_is_refused
    assert_refused(
      "task a {\n  cache \"../shared\"\n}\n",
      2,
      domain_said(Proof::InvalidPathPatternError) { Proof::PathPattern.new(path: "../shared") }
    )
  end

  # Project file reference, "Mistakes Proof catches, and one it can't": "A repeated property keeps only its last
  # value, and that is valid KDL, so Proof can't tell it apart from what you meant."
  def test_a_repeated_property_keeps_its_last_value
    assert_equal(entry("test", cpus: 4), read("task test cpus=2 cpus=4\n").entries.first)
  end

  # Command design, "The interface and the project file": "a file that isn't valid KDL 2 is refused", here for text
  # that is KDL 1.
  def test_a_file_that_is_kdl_1_is_refused
    assert_refused(
      "task a\ntask b {\n  label true\n}\n",
      3,
      "this is not valid KDL 2: Identifier cannot be a literal at column 13"
    )
  end
end
