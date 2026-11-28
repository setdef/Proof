# frozen_string_literal: true

require_relative("test_helper")
require "fileutils"
require "open3"
require "rbconfig"
require "tmpdir"

# Checks that +rake rubycritic+, the task of the gate, scores each gem alone and fails, naming the gem, when one is
# under the floor or holds a smell. It runs RubyCritic for real, over a probe repository in a folder of its own.
class RubycriticTaskTest < Minitest::Test
  TASKS = File.expand_path("../tasks/rubycritic.rake", __dir__)
  # A file that RubyCritic rates A, with no smell.
  TIDY = <<~RUBY
    # frozen_string_literal: true

    # A probe.
    module Tidy
      def self.twice(value)
        value * 2
      end
    end
  RUBY
  # A file that RubyCritic rates below A, and that pulls the score of its gem under 95.
  TANGLED = <<~RUBY
    # frozen_string_literal: true

    # A probe.
    class Tangled
      def tangle(first, second, third)
        if first
          second.each { |item| third.each { |other| puts(item + other) if item && other || first && second } }
        elsif second
          third.map { |item| item.to_s.upcase.downcase.strip.chomp.reverse }.select { |item| item.size > 2 && item.size < 40 }
        else
          first.zip(second, third).flatten.compact.uniq.sort.reverse.each_slice(3).map(&:first).reject(&:nil?).count
        end
        while first && second || third
          first = second ? third : first
          second = third ? first : second
        end
      end
    end
  RUBY
  # A file that RubyCritic rates A and that holds a smell, which reek reports as an uncommunicative variable name.
  SMELLY = <<~RUBY
    # frozen_string_literal: true

    # A probe.
    class Smelly
      def run
        a = 1
        a
      end
    end
  RUBY
  private_constant(:TASKS, :TIDY, :TANGLED, :SMELLY)

  # Yields a folder with a Rakefile for the task and a +lib+ folder of the gem at the root, and a +lib+ folder for each
  # of the +gems+, a hash from a gem's folder to the source of its file.
  def in_probe_repository(gems = {})
    Dir.mktmpdir("rubycritic-task-test") do |root|
      write(root, "Rakefile", "load(#{TASKS.inspect})\n")
      write(root, "lib/tidy.rb", TIDY)
      gems.each { |name, source| write(root, "gems/#{name}/lib/#{name}.rb", source) }
      yield(root)
    end
  end

  def write(root, path, source)
    FileUtils.mkdir_p(File.dirname(File.join(root, path)))
    File.write(File.join(root, path), source)
  end

  # The status and output of +rake rubycritic+ run in +root+.
  def run_task(root)
    output, status = Open3.capture2e(RbConfig.ruby, "-rbundler/setup", "-S", "rake", "rubycritic", chdir: root)
    [status, output]
  end

  def test_the_task_passes_when_every_gem_holds_the_gate
    in_probe_repository(tidy_gem: TIDY) do |root|
      status, output = run_task(root)

      assert_predicate(status, :success?, output)
    end
  end

  def test_the_task_fails_naming_each_gem_under_the_floor_or_with_a_smell_and_no_other
    in_probe_repository(tangled: TANGLED, tidy_gem: TIDY, smelly: SMELLY) do |root|
      status, output = run_task(root)

      refute_predicate(status, :success?, output)
      assert_match(/^ {2}tangled: the score is \d+\.\d+, under 95\.$/, output)
      assert_equal(Set["smelly", "tangled"], Set.new(output.scan(/^ {2}(\w+): /)) { |(name)| name })
    end
  end
end
