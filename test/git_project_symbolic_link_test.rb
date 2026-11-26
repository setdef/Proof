# frozen_string_literal: true

require_relative("git_fixtures")

# Checks that Proof reads a file of a commit only when the commit holds a regular file at its path, so a symbolic link
# can't make it read a file that Proof never sent. A path that is a link raises an error about the path, and reading the
# project file turns it into a refusal of the project file.
class GitProjectSymbolicLinkTest < Minitest::Test
  include GitFixtures

  CONFIG = ".config/proof.kdl"
  LINK_MESSAGE = ".config/proof.kdl: this is a symbolic link, and Proof reads only a regular file there. " \
    "Replace it with a file that holds the project file's text"
  private_constant(:CONFIG, :LINK_MESSAGE)

  # The project file of +commit+ in the project at +folder+, as the reader gives it.
  def read_project_file(folder, commit)
    Proof::ProjectFileReader.read_from(Proof::GitProject.find(folder), commit)
  end

  # A project whose file at the project file's path is a symbolic link to +target+, and the commit of it.
  def commit_with_link(target)
    folder = make_repository
    FileUtils.mkdir_p(File.join(folder, ".config"))
    File.symlink(target, File.join(folder, CONFIG))
    [folder, commit_all(folder)]
  end

  # Issue #52, item 6: "`.config/proof.kdl` committed as a symbolic link: refuse it, with a message saying Proof reads
  # only a regular file there."
  def test_a_symbolic_link_is_refused_with_the_reason
    folder, commit = commit_with_link("../elsewhere.kdl")
    error = assert_raises(Proof::ProjectFileError) { read_project_file(folder, commit) }

    assert_equal([LINK_MESSAGE, CONFIG, nil], [error.message, error.path, error.line])
  end

  # The file's path isn't only the project file's, so the error for a link names the path and the commit, and says
  # nothing of a project file.
  def test_a_link_at_any_path_is_refused_with_a_message_about_the_path
    folder, commit = commit_with_link("../elsewhere.kdl")
    error = assert_raises(Proof::SymbolicLinkError) { Proof::GitProject.find(folder).file_at(commit, CONFIG) }

    assert_equal("#{CONFIG} at #{commit} is a symbolic link, not a regular file", error.message)
  end

  # The domain's errors are all its `Proof::Error`s, so a caller that rescues them gets this one.
  def test_the_error_for_a_link_is_a_proof_error
    assert_operator(Proof::SymbolicLinkError, :<, Proof::Error)
  end

  # A commit with no project file has nothing to read, and a commit with a regular file has its settings.
  def test_a_commit_without_a_link_is_read_or_has_no_file
    folder = make_repository
    empty = commit_file(folder)
    commit = commit_file(folder, CONFIG, "task test\n")

    assert_nil(read_project_file(folder, empty))
    assert_equal(["test"], read_project_file(folder, commit).entries.map(&:name))
  end

  # The same item: "Following the link out of the commit could read a file Proof never sent", so a link to a file
  # outside the project and a link that points nowhere are refused as the link is, and not read through.
  def test_a_link_to_a_file_outside_the_project_or_to_nothing_is_refused
    [File.join(temporary_folder, "secret.kdl"), "missing.kdl"].each do |target|
      File.write(File.join(temporary_folder, "secret.kdl"), "task secret\n")
      folder, commit = commit_with_link(target)

      assert_raises(Proof::SymbolicLinkError, target) { Proof::GitProject.find(folder).file_at(commit, CONFIG) }
      assert_raises(Proof::ProjectFileError, target) { read_project_file(folder, commit) }
    end
  end

  # The same item, for a link to a folder, which Git records as a link all the same.
  def test_a_link_to_a_folder_is_refused
    folder, commit = commit_with_link("..")

    assert_raises(Proof::SymbolicLinkError) { Proof::GitProject.find(folder).file_at(commit, CONFIG) }
    assert_raises(Proof::ProjectFileError) { read_project_file(folder, commit) }
  end

  # Project file reference, "Where Proof reads the file": from "the working tree when you run `proof run`", so a
  # link in the working tree that isn't committed is refused too.
  def test_a_link_in_the_working_tree_is_refused
    folder = make_repository
    commit_file(folder)
    FileUtils.mkdir_p(File.join(folder, ".config"))
    File.symlink("../x.kdl", File.join(folder, CONFIG))
    project = Proof::GitProject.find(folder)

    assert_raises(Proof::SymbolicLinkError) { project.file_at(project.working_tree_commit_id, CONFIG) }
    assert_raises(Proof::ProjectFileError) { Proof::ProjectFileReader.read_from(project, project.working_tree_commit_id) }
  end

  # A regular file is read as it was, whatever its mode: an executable project file is a file.
  def test_a_regular_executable_file_is_read
    folder = make_repository
    write_file(folder, CONFIG, "task test\n")
    File.chmod(0o755, File.join(folder, CONFIG))
    commit = commit_all(folder)

    assert_equal("task test\n", Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end

  # The refusal is the path's own: a link at another path is the caller's to ask about, and one next to the project
  # file doesn't change what is read.
  def test_a_link_beside_the_project_file_changes_nothing
    folder = make_repository
    write_file(folder, CONFIG, "task test\n")
    File.symlink("proof.kdl", File.join(folder, ".config", "other.kdl"))
    commit = commit_all(folder)

    assert_equal("task test\n", Proof::GitProject.find(folder).file_at(commit, CONFIG))
  end
end
