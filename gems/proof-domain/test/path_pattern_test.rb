# frozen_string_literal: true

require_relative("test_helper")

# Checks the artifact patterns and cache folders a task names.
class PathPatternTest < Minitest::Test
  MESSAGE = "a path is relative to the workspace's root, so it is not empty, doesn't start with /, " \
    "and has no folder named .., such as \"pkg/*.gem\" or \"tmp/engine/build\", not %p"
  private_constant(:MESSAGE)

  # Each path that has to be refused, as the test names it.
  def assert_refused(paths)
    paths.each { |path| assert_raises(Proof::InvalidPathPatternError, path.inspect) { Proof::PathPattern.new(path:) } }
  end

  # Project file reference, "Children": an `artifact` takes "file patterns,
  # relative to the workspace's root", where "`*` matches within a folder and
  # `**` matches across folders", and the complete example has `"pkg/*.gem"`
  # and `"doc/api/**"`, so a pattern is kept as written.
  def test_a_pattern_is_kept_as_written
    patterns = ["pkg/*.gem", "doc/api/**"]

    assert_equal(patterns, patterns.map { |path| Proof::PathPattern.new(path:).path })
  end

  # Project file reference, "Children": a `cache` takes "folders, relative to
  # the workspace's root", such as `"tmp/engine/build"` and `".cache/ccache"`.
  def test_a_folder_is_kept_as_written
    folders = ["tmp/engine/build", ".cache/ccache"]

    assert_equal(folders, folders.map { |path| Proof::PathPattern.new(path:).path })
  end

  # Project file reference, "Children": paths are "relative to the workspace's
  # root", and the glossary calls the folder where a run's command runs the workspace.
  def test_a_name_with_no_folder_is_relative
    assert_equal("coverage", Proof::PathPattern.new(path: "coverage").path)
  end

  # Two patterns written alike are one value, so lists of them compare.
  def test_two_patterns_written_alike_are_equal
    assert_equal(Proof::PathPattern.new(path: "pkg/*.gem"), Proof::PathPattern.new(path: "pkg/*.gem"))
  end

  # Project file reference, "Mistakes Proof catches": a path "starts with `/`" is refused.
  def test_a_path_that_starts_with_a_slash_is_refused
    assert_refused(["/", "/tmp", "/pkg/*.gem", "//server/share"])
  end

  # Project file reference, "Mistakes Proof catches": a path that "contains
  # `..`" is refused, wherever the two dots stand.
  def test_a_path_with_a_parent_folder_is_refused
    assert_refused(["..", "../pkg", "pkg/..", "pkg/../other", "a/b/../../c", "**/../x", "a\n/../b"])
  end

  # The same sentence: the page says "contains `..`", not "has a folder named
  # `..`", so two dots inside a name are refused too.
  def test_two_dots_inside_a_name_are_refused
    assert_refused(["a..b", "v1..2.txt", "...", "..a", "a..", "pkg/a..b/c", "pkg/...", "x/..."])
  end

  # A single dot is not `..`, so a hidden file or folder and a file extension are kept.
  def test_a_single_dot_is_kept
    [".hidden", "a.b", "pkg/.cache/ccache", "pkg/a.b.c", "./pkg"].each do |path|
      assert_equal(path, Proof::PathPattern.new(path:).path)
    end
  end

  # Project file reference, "Mistakes Proof catches": the paths are in `artifact`
  # and `cache` nodes that take "One or more", so a path of no characters is no path.
  def test_an_empty_path_is_refused
    assert_refused([""])
  end

  # Project file reference, "Mistakes Proof catches": "a value has the wrong
  # type", so anything but text is refused.
  def test_a_path_that_is_not_text_is_refused
    assert_refused([nil, 1, :"pkg/*.gem", ["pkg"]])
  end

  # A string with a byte that isn't valid text can't be searched for a `..`, so
  # it is refused with the path's error, not Ruby's.
  def test_a_path_with_invalid_bytes_is_refused
    error = assert_raises(Proof::InvalidPathPatternError) { Proof::PathPattern.new(path: "pkg/\xFF") }

    assert_equal(format(MESSAGE, "pkg/\xFF"), error.message)
  end

  # A string in an encoding that isn't ASCII-compatible, such as UTF-16, is valid
  # text but can't be searched for a `..`, so it is refused with the path's error.
  def test_a_path_in_an_encoding_that_is_not_ascii_compatible_is_refused
    assert_refused(["pkg".encode(Encoding::UTF_16LE)])
  end

  # Project file reference, "Mistakes Proof catches": "Proof refuses a project
  # file, with the line and the reason", so the message says what is wrong and
  # what works.
  def test_the_message_names_the_value_and_the_forms_that_work
    error = assert_raises(Proof::InvalidPathPatternError) { Proof::PathPattern.new(path: "/tmp") }

    assert_equal(format(MESSAGE, "/tmp"), error.message)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidPathPatternError, :<, Proof::Error)
  end
end
