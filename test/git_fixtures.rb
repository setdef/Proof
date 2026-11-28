# frozen_string_literal: true

require_relative("test_helper")
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

# Makes real Git repositories in temporary folders for tests, and runs the
# `git` program in them with no `GIT_*` variable inherited from whatever runs
# the tests, such as a hook.
module GitFixtures
  IDENTITY = %w[-c user.name=Tester -c user.email=tester@example.com -c commit.gpgsign=false].freeze
  ALLOW_LOCAL_CLONES = %w[-c protocol.file.allow=always].freeze
  private_constant(:IDENTITY, :ALLOW_LOCAL_CLONES)

  # The variables of a process, as Ruby's environment holds them: names and values are strings.
  def variables(**named)
    named.to_h { |name, value| [name.to_s, value.to_s] }
  end

  # What a Ruby process prints when it loads Proof and runs +script+ with
  # +arguments+ in ARGV, with the +hook+ variables set, as a Git hook sets them
  # for the programs it starts.
  def printed_in_hook(hook, script, *arguments)
    printed(hook, script, arguments)
  end

  # What a Ruby process prints when it loads Proof and runs +script+, as +printed_in_hook+ does, but with
  # only +PATH+ and +named+ in its environment. Nothing else of the environment that runs the tests reaches
  # it, such as a variable that an agent's harness sets or a person's Git identity, so the result is the
  # same on every computer that has Git.
  def printed_in_clean_environment(named, script, *arguments)
    printed(variables(PATH: ENV.fetch("PATH")).merge(named), script, arguments, unsetenv_others: true)
  end

  private def printed(environment, script, arguments, unsetenv_others: false)
    load_path = %w[lib gems/proof-domain/lib gems/usage-rb/lib].map { |path| File.expand_path("../#{path}", __dir__) }
    options = load_path.flat_map { |path| ["-I", path] }
    command = [RbConfig.ruby, *options, "-e", "require('proof'); #{script}", *arguments]
    output, error, status = Open3.capture3(environment, *command, unsetenv_others:)

    assert_predicate(status, :success?, error)
    output
  end

  # Runs `git` with +arguments+ in +folder+, and returns what it prints. Fails
  # the test when git exits with a status other than 0.
  def git(folder, *arguments, input: "")
    command = ["git", *IDENTITY, *ALLOW_LOCAL_CLONES, *arguments]
    output, error, status = Open3.capture3(Proof::Git.cleared_environment, *command, chdir: folder, stdin_data: input)

    assert_predicate(status, :success?, "git #{arguments.join(' ')} failed: #{error}")
    output
  end

  # A new temporary folder, removed when the test ends, and its real path.
  def temporary_folder
    folder = Dir.mktmpdir("proof-git-test")
    (@temporary_folders ||= []) << folder
    File.realpath(folder)
  end

  # Removes the folders the test made.
  def after_teardown
    super
    (@temporary_folders || []).each { |folder| FileUtils.remove_entry(folder) }
  end

  # A new repository, with the branch `trunk`, in a folder of its own.
  def make_repository(name = "project")
    folder = File.join(temporary_folder, name)
    FileUtils.mkdir_p(folder)
    git(folder, "init", "--quiet", "--initial-branch=trunk")
    folder
  end

  # Writes +content+ to +path+ inside +folder+, making the folders on the way.
  def write_file(folder, path, content)
    full = File.join(folder, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
  end

  # Commits everything in +folder+, and returns the new commit's ID.
  def commit_all(folder, message = "A change")
    git(folder, "add", "-A")
    git(folder, "commit", "--quiet", "-m", message)
    git(folder, "rev-parse", "HEAD").chomp
  end

  # Commits everything in +folder+, ignored files too, and returns the commit's ID.
  def commit_all_with_ignored(folder)
    git(folder, "add", "-A", "--force")
    git(folder, "commit", "--quiet", "-m", "A change")
    git(folder, "rev-parse", "HEAD").chomp
  end

  # Writes +content+ to +path+ in +folder+, commits everything, and returns the commit's ID.
  def commit_file(folder, path = "a.txt", content = "1")
    write_file(folder, path, content)
    commit_all(folder)
  end

  # A clone of a new repository that has one commit, made with `--filter=blob:none`
  # as a partial clone is. Returns the clone's folder.
  def make_partial_clone
    source = make_repository("source")
    commit_file(source)
    git(source, "config", "uploadpack.allowFilter", "true")
    parent = temporary_folder
    git(parent, "clone", "--quiet", "--filter=blob:none", "file://#{source}", "partial")
    File.join(parent, "partial")
  end

  # The paths in the tree of +commit+ with the mode of each, as pairs sorted by path.
  def tree(folder, commit)
    entries = git(folder, "ls-tree", "-r", commit).lines.map do |line|
      mode, _type, _id, path = line.split(/\s+/, 4)
      [path.chomp, mode]
    end
    entries.sort
  end

  # The working-tree commit of the project in +folder+.
  def working_tree_commit(folder)
    Proof::GitProject.find(folder).working_tree_commit_id
  end

  # A project that records a submodule at `vendor/sub`, with the submodule's
  # clone absorbed into the project's `.git/modules`, as Git makes it. Returns
  # the project's folder and the commit that the project records for the submodule.
  def make_project_with_submodule
    sub = make_repository("sub")
    recorded = commit_file(sub, "lib.txt", "1")
    folder = make_repository
    commit_file(folder)
    git(folder, "submodule", "--quiet", "add", sub, "vendor/sub")
    commit_all(folder)
    [folder, recorded]
  end
end
