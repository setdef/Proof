# frozen_string_literal: true

require_relative("test_helper")
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

# Checks that the domain gem depends on nothing but Ruby's standard library.
#
# Each check loads the gem in a fresh Ruby process, which starts with the
# same files loaded as any other, then lists what the load added. A process
# that already ran the tests would hide a file the tests loaded themselves.
class DomainDependencyTest < Minitest::Test
  GEM_LIB = File.expand_path("../lib", __dir__)
  LOAD = <<~RUBY
    before = $LOADED_FEATURES.dup
    require("proof/domain")
    puts($LOADED_FEATURES - before)
  RUBY
  private_constant(:GEM_LIB, :LOAD)

  # The files that loading the gem in +lib+ added, other than the gem's own
  # and Ruby's standard library.
  def loaded_outside(lib)
    out, err, status = Open3.capture3(RbConfig.ruby, "-I", lib, "-e", LOAD)

    assert_predicate(status, :success?, err)
    assert_empty(err)
    paths = out.lines.map { |line| File.realpath(line.chomp) }
    paths.reject { |path| own_or_standard?(path, lib) }
  end

  # Whether +path+ is in +lib+ or in Ruby's standard library.
  def own_or_standard?(path, lib)
    roots = [lib, RbConfig::CONFIG["rubylibdir"], RbConfig::CONFIG["rubyarchdir"]]
    roots.any? { |root| path.start_with?("#{File.realpath(root)}/") }
  end

  # The gem's lib folder, copied with one line added to the file that loads
  # the rest, and what loading the copy added from outside.
  def loaded_outside_after_adding(line)
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(GEM_LIB, dir)
      File.write(File.join(dir, "lib/proof/domain.rb"), "#{line}\n", mode: "a")
      loaded_outside(File.join(dir, "lib"))
    end
  end

  # "a test fails if the gem loads anything outside itself"
  # (doc/contributors/architecture.md, "The domain gem and the code around it").
  def test_the_gem_loads_nothing_outside_itself_and_the_standard_library
    assert_empty(loaded_outside(GEM_LIB))
  end

  # The same check, run on a copy that requires another gem, reports it.
  def test_a_require_of_another_gem_is_reported
    assert_match(%r{/minitest\.rb\z}, loaded_outside_after_adding('require("minitest")').join("\n"))
  end

  # The same check, run on a copy that requires the code around the gem,
  # reports it: the domain never depends on lib/proof.
  def test_a_require_of_the_code_around_the_gem_is_reported
    assert_match(%r{/proof/version\.rb\z}, loaded_outside_after_adding('require("proof/version")').join("\n"))
  end

  # The same check, run on a copy that requires the standard library, reports nothing.
  def test_a_require_of_the_standard_library_is_allowed
    assert_empty(loaded_outside_after_adding('require("set")'))
  end
end
