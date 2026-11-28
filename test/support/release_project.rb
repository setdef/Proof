# frozen_string_literal: true

require_relative("../test_helper")
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

# What the tests of the release's version share: a small project laid out as Proof is, locked at 0.0.0, which each test
# copies to a folder of its own and stamps, so that no test touches this checkout.
module ReleaseProject
  # Runs +command+ in +root+ as a person's shell would, with no bundle of this test run, and with the lockfile frozen
  # as CI freezes it when +frozen+ is true.
  def self.run_in(root, *command, frozen: false)
    Bundler.with_unbundled_env do
      Open3.capture2e({ "BUNDLE_FROZEN" => frozen.to_s }, *command, chdir: root)
    end
  end

  # The project, which takes a second to lock. It is made when a test first asks for it, in a folder that goes when
  # the tests end.
  class Template
    GEMSPEC = <<~RUBY
      Gem::Specification.new do |spec|
        spec.name = "proof"
        spec.version = File.read(File.expand_path("lib/proof/version.rb", __dir__))[/VERSION = "([^"]+)"/, 1]
        spec.authors = ["setdef"]
        spec.summary = "A project to stamp"
      end
    RUBY
    private_constant(:GEMSPEC)

    def initialize
      @lock = Mutex.new
    end

    # The folder that holds the project.
    def root
      @lock.synchronize { @root ||= build }
    end

    private def build
      Dir.mktmpdir("release-project-template").tap do |root|
        Minitest.after_run { FileUtils.remove_entry(root) }
        FileUtils.mkdir_p(File.join(root, "lib", "proof"))
        File.write(File.join(root, "proof.gemspec"), GEMSPEC)
        File.write(File.join(root, "Gemfile"), "source \"https://rubygems.org\"\ngemspec\n")
        File.write(File.join(root, "lib", "proof", "version.rb"), "module Proof\n  VERSION = \"0.0.0\"\nend\n")
        output, status = ReleaseProject.run_in(root, "bundle", "lock")
        raise(output) unless status.success?
      end
    end
  end

  TEMPLATE = Template.new
  private_constant(:TEMPLATE)

  def run_in(...)
    ReleaseProject.run_in(...)
  end

  # Yields a copy of the project, in a folder that goes when the block ends.
  def in_project
    Dir.mktmpdir("release-project-test") do |root|
      FileUtils.cp_r(File.join(TEMPLATE.root, "."), root)
      yield(root)
    end
  end

  def read(root, path)
    File.read(File.join(root, path))
  end

  # The files a stamp changes, as a hash, so a test can tell that none changed.
  def files(root)
    %w[lib/proof/version.rb Gemfile.lock].to_h { |path| [path, read(root, path)] }
  end

  # The version that Proof::VERSION has in +root+, which is what the built program reports.
  def reported(root)
    output, = run_in(root, RbConfig.ruby, "-e", "require './lib/proof/version'; print Proof::VERSION")
    output
  end

  # Fails unless the version file, the lockfile, and a frozen install of +root+ all agree on +version+.
  def assert_agree(root, version)
    assert_equal(version, reported(root))
    assert_includes(read(root, "Gemfile.lock"), "    proof (#{version})\n")
    output, status = run_in(root, "bundle", "install", "--local", frozen: true)

    assert_predicate(status, :success?, output)
  end
end
