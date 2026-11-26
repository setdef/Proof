# frozen_string_literal: true

require_relative("git_fixtures")

# Checks how Proof reads a file of the code it sends, which is the project file's source.
class GitProjectFileTest < Minitest::Test
  include GitFixtures

  CONFIG = ".config/proof.kdl"
  private_constant(:CONFIG)

  # Project file reference, "Where Proof reads the file": "Proof reads `.config/proof.kdl` from what it
  # sends, not from your disk: ... from the commit when you run `proof run --commit REV`", so the text is the commit's.
  def test_a_file_is_read_from_the_commit
    folder = make_repository
    commit = commit_file(folder, CONFIG, "task test\n")

    assert_equal("task test\n", Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # The same sentence: "not from your disk", so a change on disk that the commit doesn't hold isn't read.
  def test_a_change_on_disk_is_not_read
    folder = make_repository
    commit = commit_file(folder, CONFIG, "task test\n")
    write_file(folder, CONFIG, "task other\n")

    assert_equal("task test\n", Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # The same sentence: a file deleted from disk is still in the commit.
  def test_a_file_deleted_from_disk_is_still_read
    folder = make_repository
    commit = commit_file(folder, CONFIG, "task test\n")
    FileUtils.rm(File.join(folder, CONFIG))

    assert_equal("task test\n", Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # Project file reference, "Where Proof reads the file": "from the working tree when you run `proof run`", and
  # "A change to the project file is in effect for the next run, committed or not."
  def test_a_change_that_is_not_committed_is_read_from_the_working_tree_commit
    folder = make_repository
    commit_file(folder, CONFIG, "task test\n")
    write_file(folder, CONFIG, "task other\n")
    project = Proof::GitProject.find(folder)

    assert_equal("task other\n", project.file_at(project.working_tree_commit_id, CONFIG))
  end

  # The same sentence: a project file that is new, and untracked, is in effect for the next run.
  def test_a_new_file_is_read_from_the_working_tree_commit
    folder = make_repository
    commit_file(folder)
    write_file(folder, CONFIG, "task new\n")
    project = Proof::GitProject.find(folder)

    assert_equal("task new\n", project.file_at(project.working_tree_commit_id, CONFIG))
  end

  # Project file reference, "The file is optional. Without it, `proof run NAME` runs `mise run NAME`": a commit
  # with no project file gives `nil`, not an empty text.
  def test_a_commit_without_the_file_gives_nil
    folder = make_repository
    commit = commit_file(folder, "a.txt", "1")

    assert_nil(Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # The same sentence, for an empty file: it is a project file with nothing in it, so its text is `""`.
  def test_an_empty_file_gives_an_empty_text
    folder = make_repository
    commit = commit_file(folder, CONFIG, "")

    assert_equal("", Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # Project file reference, "Where Proof reads the file": "Proof reads only this one file", so a file of the
  # same name in a subfolder, and a file with a longer name, aren't it.
  def test_only_the_named_path_is_read
    folder = make_repository
    write_file(folder, "sub/.config/proof.kdl", "task sub\n")
    write_file(folder, ".config/proof.kdl.bak", "task bak\n")
    commit = commit_all(folder)

    assert_nil(Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # A folder with the file's name isn't a file, so it gives `nil`.
  def test_a_folder_gives_nil
    folder = make_repository
    commit = commit_file(folder, ".config/proof.kdl/inner.txt", "x")

    assert_nil(Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # The text is what the commit holds, byte for byte, so a reader sees an invalid byte as it is.
  def test_the_bytes_are_returned_as_they_are
    folder = make_repository
    bytes = "task caf\xC3\xA9\n# \xFF\n".b
    write_file(folder, CONFIG, bytes)
    commit = commit_all(folder)

    assert_equal(bytes, Proof::GitProject.find(folder).file_at(commit, CONFIG).b)
  end

  # A path that starts with a dash is a path to look up, not an option.
  def test_a_path_that_looks_like_an_option_is_a_path
    folder = make_repository
    commit = commit_file(folder, "-n", "x")

    assert_equal("x", Proof::GitProject.find(folder).file_at(commit, "-n"))
  end

  # A commit that isn't one is refused, not read as a commit with no file.
  def test_a_commit_that_is_not_a_commit_is_refused
    folder = make_repository
    commit_file(folder)

    assert_raises(Proof::UnknownRevisionError) { Proof::GitProject.find(folder).file_at("0" * 40, CONFIG) }
  end

  # Command design, "Which project and which code": "Partial clones can't send all a commit's objects, because
  # they don't have them. Refuse with a message that says so."
  def test_a_partial_clone_is_refused
    root = make_partial_clone

    assert_raises(Proof::PartialCloneError) { Proof::GitProject.find(root).file_at("HEAD", CONFIG) }
  end
end
