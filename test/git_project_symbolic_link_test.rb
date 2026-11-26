# frozen_string_literal: true

require_relative("git_fixtures")

# Checks that Proof reads the project file only when the commit holds a regular file at its path, so a symbolic link
# can't make it read a file that Proof never sent.
class GitProjectSymbolicLinkTest < Minitest::Test
  include GitFixtures

  CONFIG = ".config/proof.kdl"
  MESSAGE = ".config/proof.kdl: this is a symbolic link, and Proof reads only a regular file there. " \
    "Replace it with a file that holds the project file's text"
  private_constant(:CONFIG, :MESSAGE)

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
    error = assert_raises(Proof::ProjectFileError) { Proof::GitProject.find(folder).file_at(commit, CONFIG) }

    assert_equal([MESSAGE, CONFIG, nil], [error.message, error.path, error.line])
  end

  # The same item: "Following the link out of the commit could read a file Proof never sent", so a link to a file
  # outside the project and a link that points nowhere are refused as the link is, and not read through.
  def test_a_link_to_a_file_outside_the_project_or_to_nothing_is_refused
    [File.join(temporary_folder, "secret.kdl"), "missing.kdl"].each do |target|
      File.write(File.join(temporary_folder, "secret.kdl"), "task secret\n")
      folder, commit = commit_with_link(target)

      assert_raises(Proof::ProjectFileError, target) { Proof::GitProject.find(folder).file_at(commit, CONFIG) }
    end
  end

  # The same item, for a link to a folder, which Git records as a link all the same.
  def test_a_link_to_a_folder_is_refused
    folder, commit = commit_with_link("..")

    assert_raises(Proof::ProjectFileError) { Proof::GitProject.find(folder).file_at(commit, CONFIG) }
  end

  # Project file reference, "Where Proof reads the file": from "the working tree when you run `proof run`", so a
  # link in the working tree that isn't committed is refused too.
  def test_a_link_in_the_working_tree_is_refused
    folder = make_repository
    commit_file(folder)
    FileUtils.mkdir_p(File.join(folder, ".config"))
    File.symlink("../x.kdl", File.join(folder, CONFIG))
    project = Proof::GitProject.find(folder)

    assert_raises(Proof::ProjectFileError) { project.file_at(project.working_tree_commit_id, CONFIG) }
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
