# frozen_string_literal: true

require_relative("git_fixtures")

# Checks how Proof reads a revision of a project, and which clones it refuses.
class GitProjectRevisionTest < Minitest::Test
  include GitFixtures

  # How-proof-works, "How your code reaches a runner": "With `--commit REV`, that is the commit you
  # named", and the run needs its ID in full. Each form of a revision resolves to 40 hexadecimal digits.
  def test_a_revision_resolves_to_a_full_commit_id
    folder = make_repository
    first = commit_file(folder, "a.txt", "1")
    second = commit_file(folder, "a.txt", "2")
    git(folder, "branch", "side", first)
    project = Proof::GitProject.find(folder)
    revisions = ["HEAD", "HEAD~1", "side", "trunk", second[0, 8]]

    assert_equal([second, first, first, second, second], revisions.map { |revision| project.commit_id(revision) })
    assert_match(/\A\h{40}\z/, project.commit_id("HEAD"))
  end

  # The same sentence, for an annotated tag: the run needs the commit, not the tag object.
  def test_an_annotated_tag_resolves_to_the_commit_it_marks
    folder = make_repository
    commit = commit_file(folder)
    git(folder, "tag", "--annotate", "--message=release", "v1")

    assert_equal(commit, Proof::GitProject.find(folder).commit_id("v1"))
  end

  # Command design, "Output and exit status": errors say what to do next; a revision that is no commit is refused.
  def test_a_revision_that_is_not_a_commit_is_refused
    folder = make_repository
    commit_file(folder)
    error = assert_raises(Proof::UnknownRevisionError) { Proof::GitProject.find(folder).commit_id("no-such-branch") }

    assert_equal(
      [
        "no-such-branch is not a commit in #{folder}.",
        "Check the spelling, or run git fetch if it is a branch or tag that the project's remote has.",
    ].join(" "),
      error.message
    )
  end

  # How-proof-works, "How your code reaches a runner": with `--commit REV` the run needs the commit you named,
  # and a project with no commit has none, so each revision is refused with the cause.
  def test_a_revision_in_a_project_with_no_commit_is_refused
    folder = make_repository
    write_file(folder, "a.txt", "1")
    project = Proof::GitProject.find(folder)

    %w[HEAD trunk].each do |revision|
      error = assert_raises(Proof::UnknownRevisionError) { project.commit_id(revision) }

      assert_match(/\A#{revision} is not a commit in #{Regexp.escape(folder)}\./, error.message)
    end
  end

  # A tree is a revision to Git but not a commit, and a run needs a commit.
  def test_a_tree_is_refused_as_a_revision
    folder = make_repository
    commit_file(folder)

    assert_raises(Proof::UnknownRevisionError) { Proof::GitProject.find(folder).commit_id("HEAD^{tree}") }
  end

  # Text a person typed can look like an option. It is a revision to look up, so a flag such as
  # `--default=HEAD` can't change the answer.
  def test_a_revision_that_looks_like_an_option_is_not_an_option
    folder = make_repository
    commit_file(folder)

    assert_raises(Proof::UnknownRevisionError) { Proof::GitProject.find(folder).commit_id("--default=HEAD") }
  end

  # Command design, "Which project and which code": "Partial clones can't send all a commit's objects,
  # because they don't have them. Refuse with a message that says so."
  def test_a_partial_clone_is_refused_and_the_message_says_why
    root = make_partial_clone
    error = assert_raises(Proof::PartialCloneError) { Proof::GitProject.find(root).commit_id("HEAD") }

    assert_equal(
      [
        "#{root} is a partial clone, so it lacks objects of the commits that Proof sends.",
        "Clone the project again without --filter, and run proof from that clone.",
    ].join(" "),
      error.message
    )
  end

  # Older Git marks a partial clone with `extensions.partialclone` and no `promisor` setting on a remote.
  def test_a_repository_with_the_older_partial_clone_setting_is_refused
    folder = make_repository
    commit_file(folder)
    git(folder, "config", "extensions.partialclone", "origin")

    assert_raises(Proof::PartialCloneError) { Proof::GitProject.find(folder).commit_id("HEAD") }
  end

  # The setting that current Git writes for each remote a partial clone came from, with no other sign of one.
  def test_a_repository_with_a_promisor_remote_is_refused
    folder = make_repository
    commit_file(folder)
    git(folder, "config", "remote.origin.promisor", "true")

    assert_raises(Proof::PartialCloneError) { Proof::GitProject.find(folder).commit_id("HEAD") }
  end

  # A remote that isn't a promisor, and a setting with no value, don't make a clone partial.
  def test_settings_that_are_not_signs_of_a_partial_clone_are_not_refused
    folder = make_repository
    commit = commit_file(folder)
    git(folder, "config", "remote.origin.promisor", "false")
    git(folder, "config", "remote.origin.url", "https://example.com/promisor=true")
    git(folder, "config", "extensions.partialclone", "")

    assert_equal(commit, Proof::GitProject.find(folder).commit_id("HEAD"))
  end

  # A git that fails to list the settings, here with status 128 as a damaged configuration does, can't say
  # whether the clone is partial. That is a Git failure, not a revision that is no commit.
  def test_a_failing_partial_clone_check_is_a_git_failure_not_an_unknown_revision
    program = File.join(temporary_folder, "git-that-fails-on-config")
    script = "#!/bin/sh\ncase \"$1\" in config) echo 'fatal: bad config' >&2; exit 128 ;; esac\nexec git \"$@\"\n"
    File.write(program, script)
    File.chmod(0o755, program)
    folder = make_repository
    commit_file(folder)
    error = assert_raises(Proof::GitFailedError) { Proof::GitProject.new(root: folder, program:).commit_id("HEAD") }

    assert_equal([128, "fatal: bad config\n"], [error.status.exitstatus, error.error_output])
  end

  # The same requirement from the other side: a full clone, even of a local repository, is sent.
  def test_a_full_clone_is_not_refused
    source = make_repository("source")
    commit = commit_file(source)
    parent = temporary_folder
    git(parent, "clone", "--quiet", source, "full")

    assert_equal(commit, Proof::GitProject.find(File.join(parent, "full")).commit_id("HEAD"))
  end

  # Both refusals are Proof errors.
  def test_the_other_refusals_are_proof_errors
    assert_operator(Proof::UnknownRevisionError, :<, Proof::Error)
    assert_operator(Proof::PartialCloneError, :<, Proof::Error)
  end
end
