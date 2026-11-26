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
  HOOK_SCRIPT = <<~RUBY
    require("proof")
    folder, program, *arguments = ARGV
    print(Proof::Git.new(folder:, program:).run(*arguments))
  RUBY
  private_constant(:IDENTITY, :ALLOW_LOCAL_CLONES, :HOOK_SCRIPT)

  # The variables of a process, as Ruby's environment holds them: names and values are strings.
  def variables(**named)
    named.to_h { |name, value| [name.to_s, value.to_s] }
  end

  # What a Ruby process prints when Proof's `Proof::Git` runs +arguments+ in
  # +folder+ with the +hook+ variables set, as a Git hook sets them for the
  # programs it starts. The first of the +arguments+ is the program.
  def printed_in_hook(hook, folder, *arguments)
    load_path = [File.expand_path("../lib", __dir__), File.expand_path("../gems/proof-domain/lib", __dir__)]
    command = [RbConfig.ruby, *load_path.flat_map { |path| ["-I", path] }, "-e", HOOK_SCRIPT, folder, *arguments]
    output, error, status = Open3.capture3(hook, *command)

    assert_predicate(status, :success?, error)
    output
  end

  # Runs `git` with +arguments+ in +folder+, and returns what it prints. Fails
  # the test when git exits with a status other than 0.
  def git(folder, *arguments, input: "")
    inherited = ENV.keys.grep(/\AGIT_/).to_h { |name| [name, nil] }
    command = ["git", *IDENTITY, *ALLOW_LOCAL_CLONES, *arguments]
    output, error, status = Open3.capture3(inherited, *command, chdir: folder, stdin_data: input)

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
end
