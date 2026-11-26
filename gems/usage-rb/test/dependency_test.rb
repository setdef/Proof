# frozen_string_literal: true

require_relative("test_helper")
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

# Checks that the gem loads nothing but Ruby's standard library and its own files, each time in a fresh Ruby process,
# which starts with the same files loaded as any other.
class UsageDependencyTest < Minitest::Test
  LIB = File.expand_path("../lib", __dir__)
  LOAD = <<~RUBY
    before = $LOADED_FEATURES.dup
    require("usage")
    puts($LOADED_FEATURES - before)
  RUBY
  private_constant(:LIB, :LOAD)

  # The files that loading the gem in +lib+ added, other than its own and Ruby's standard library. The process runs
  # without RubyGems and without the variables Bundler sets, so a library loads from the standard library and not
  # from a newer gem of the same name in the bundle.
  def loaded_outside(lib)
    env = %w[RUBYOPT RUBYLIB].to_h { |name| [name, nil] }
    out, err, status = Open3.capture3(env, RbConfig.ruby, "--disable-gems", "-I", lib, "-e", LOAD)

    assert_predicate(status, :success?, err)
    out.lines.filter_map do |line|
      path = File.realpath(line.chomp)
      path unless within?(path, lib)
    end
  end

  # Whether +path+ is in +lib+ or in Ruby's standard library.
  def within?(path, lib)
    [lib, RbConfig::CONFIG["rubylibdir"], RbConfig::CONFIG["rubyarchdir"]].any? do |root|
      path.start_with?("#{File.realpath(root)}/")
    end
  end

  # What loading a copy of the gem, whose entry file also requires a file beside the copy, added from outside.
  def loaded_outside_after_requiring_a_file_beside_it
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(LIB, dir)
      File.write(File.join(dir, "beside.rb"), "")
      File.write(File.join(dir, "lib/usage.rb"), "require_relative(\"../beside\")\n", mode: "a")
      loaded_outside(File.join(dir, "lib"))
    end
  end

  # The gem has no runtime dependency outside Ruby's standard library.
  def test_the_gem_loads_nothing_outside_itself_and_the_standard_library
    assert_empty(loaded_outside(LIB))
  end

  # The check reports a file from outside, so the test above can fail.
  def test_a_file_outside_the_gem_is_reported
    assert_match(%r{/beside\.rb\z}, loaded_outside_after_requiring_a_file_beside_it.join("\n"))
  end
end
