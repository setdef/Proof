# frozen_string_literal: true

require_relative("support/project_file_reader_helper")

# Checks that the reader of the project file builds what the project file page says each form means.
class ProjectFileReaderTest < Minitest::Test
  include ProjectFileReaderHelper

  EVERYTHING = {
    cpus: 4,
    memory: "8GB",
    timeout: "45m",
    os: %w[linux macos],
    label: ["gpu"],
    artifact: ["pkg/*.gem"],
    cache: ["tmp/build"],
  }.freeze
  EVERYTHING_TEXT = <<~KDL
    defaults cpus=4 memory="8GB" timeout="45m" {
      os linux macos
      label gpu
      artifact "pkg/*.gem"
      cache "tmp/build"
    }
  KDL
  private_constant(:EVERYTHING, :EVERYTHING_TEXT)

  # Project file reference, "A complete example": the page's own text, read by the reader, is the project file that
  # the domain's tests build by hand from the same description.
  def test_the_complete_example_reads_as_the_project_file_the_domain_builds
    assert_equal(complete_example, read(page_example("## A complete example")))
  end

  # Project file reference, "The file is optional": an empty file has no defaults and no entries, as no file does.
  def test_an_empty_file_has_nothing
    assert_equal(Proof::ProjectFile.none, read(""))
  end

  # The same sentence: a file of comments has no nodes, so it has nothing either.
  def test_a_file_of_comments_has_nothing
    assert_equal(Proof::ProjectFile.none, read("// Proof's settings\n/* none yet */\n"))
  end

  # Project file reference, "`task`": "Without `COMMAND`, the entry adds Proof's settings to the mise task of the same
  # name", so an entry that is only a name has no command and settings that give nothing.
  def test_a_task_with_only_a_name_has_no_command_and_no_settings
    assert_equal(Proof::ProjectFile.new(entries: [entry("test")]), read("task test\n"))
  end

  # Project file reference, "`task`": "With `COMMAND`, the entry defines a task with that command."
  def test_a_task_with_a_command_has_it
    assert_equal(entry("docs", "bundle exec rake rdoc"), read("task docs \"bundle exec rake rdoc\"\n").entries.first)
  end

  # Project file reference, "`task`": "Task names follow mise's rules, so `test`, `lint:ruby`, and `package-native`
  # are all valid", and the entries are in the order the file has them.
  def test_task_names_are_kept_in_the_order_written
    names = read("task test\ntask \"lint:ruby\"\ntask package-native\n").entries.map(&:name)

    assert_equal(%w[test lint:ruby package-native], names)
  end

  # Project file reference, "Properties": `cpus` is "A whole number from 1", `memory` is "A quoted size", and
  # `timeout` is "A quoted duration", on a task as on `defaults`.
  def test_a_task_has_its_properties
    text = "task test cpus=4 memory=\"12GB\" timeout=\"90s\"\n"

    assert_equal(entry("test", cpus: 4, memory: "12GB", timeout: "90s"), read(text).entries.first)
  end

  # Project file reference, "`defaults`": it "takes the same properties and children as a `task`, except a command".
  def test_the_defaults_have_the_same_properties_and_children
    assert_equal(given(**EVERYTHING), read(EVERYTHING_TEXT).defaults)
  end

  # Project file reference, "Children": each child takes "one or more" arguments, and the lists of one entry are
  # separate settings.
  def test_a_task_has_its_children
    text = "task test {\n  os windows linux\n  label desktop \"4k\"\n  artifact \"a/*\" b\n  cache c d\n}\n"
    expected = entry("test", os: %w[windows linux], label: %w[desktop 4k], artifact: %w[a/* b], cache: %w[c d])

    assert_equal(expected, read(text).entries.first)
  end

  # Project file reference, "Examples", "Request more memory for one task".
  def test_the_page_example_that_requests_more_memory
    assert_equal(
      Proof::ProjectFile.new(entries: [entry("package", memory: "12GB")]),
      read(page_example("## Examples\n\n### Request more memory for one task"))
    )
  end

  # Project file reference, "Examples", "A task for one operating system".
  def test_the_page_example_for_one_operating_system
    assert_equal(
      Proof::ProjectFile.new(entries: [entry("ios", "bin/test-ios", os: ["macos"], label: ["desktop"])]),
      read(page_example("### A task for one operating system"))
    )
  end

  # Project file reference, "Examples", "Keep the gems a build makes, and download them".
  def test_the_page_example_that_keeps_the_gems
    assert_equal(
      Proof::ProjectFile.new(entries: [entry("package", artifact: ["pkg/*.gem"])]),
      read(page_example("### Keep the gems a build makes, and download them"))
    )
  end

  # Project file reference, "Examples", "Keep a compiler cache between runs".
  def test_the_page_example_that_keeps_a_compiler_cache
    assert_equal(
      Proof::ProjectFile.new(defaults: given(cache: [".cache/ccache"])),
      read(page_example("### Keep a compiler cache between runs"))
    )
  end

  # Project file reference, "`defaults`": the block syntax of the page.
  def test_the_page_example_of_the_defaults_node
    assert_equal(
      Proof::ProjectFile.new(defaults: given(cpus: 4, memory: "8GB", timeout: "45m", os: %w[linux macos windows])),
      read(page_example("## `defaults`"))
    )
  end

  # Project file reference, "Where Proof reads the file": a refusal names the file, and the file is
  # `.config/proof.kdl` unless the caller reads another.
  def test_a_refusal_names_the_file_it_read
    default = assert_raises(Proof::ProjectFileError) { Proof::ProjectFileReader.read("task\n") }
    other = assert_raises(Proof::ProjectFileError) { Proof::ProjectFileReader.read("task\n", path: "other.kdl") }

    assert_equal([".config/proof.kdl", "other.kdl"], [default.path, other.path])
  end
end
