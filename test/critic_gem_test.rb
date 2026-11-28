# frozen_string_literal: true

require_relative("test_helper")
require "fileutils"
require "tmpdir"

# SimpleCov starts in test_helper, so it must load before the code it measures.
require_relative("../tasks/critic_gem")

# Checks which gems the RubyCritic gate scores alone, over which paths, and what it says about each that fails.
class CriticGemTest < Minitest::Test
  # Yields a folder that has each of the +folders+.
  def in_repository(*folders)
    Dir.mktmpdir("critic-gem-test") do |root|
      FileUtils.mkdir_p(folders.map { |folder| File.join(root, folder) })
      yield(root)
    end
  end

  # RubyCritic's JSON report of one file rated +rating+ with the given +score+.
  def report(score, rating: "A")
    JSON.generate(score:, analysed_modules: [{ name: "A", path: "lib/a.rb", rating:, smells: [] }])
  end

  def test_the_root_gem_is_proof_over_its_lib_and_sig
    in_repository("lib", "sig") do |root|
      assert_equal([CriticGem.new(name: "proof", paths: %w[lib sig])], CriticGem.in_repository(root))
    end
  end

  def test_the_root_gem_has_only_the_folders_that_exist
    in_repository("lib") do |root|
      assert_equal(%w[lib], CriticGem.in_repository(root).first.paths)
    end
  end

  def test_each_gem_of_the_gems_folder_is_scored_alone_over_its_own_paths_by_name
    in_repository("lib", "sig", "gems/usage-rb/lib", "gems/usage-rb/sig", "gems/domain/lib") do |root|
      gems = CriticGem.in_repository(root)

      assert_equal(%w[proof domain usage-rb], gems.map(&:name))
      assert_equal(["gems/usage-rb/lib", "gems/usage-rb/sig"], gems.last.paths)
      assert_equal(["gems/domain/lib"], gems[1].paths)
    end
  end

  def test_a_folder_of_gems_without_a_lib_is_no_gem
    in_repository("lib", "gems/notes/docs") do |root|
      assert_equal(%w[proof], CriticGem.in_repository(root).map(&:name))
    end
  end

  def test_a_gem_at_the_floor_has_no_faults
    assert_empty(CriticGem.new(name: "usage-rb", paths: []).faults(report(95.0), floor: 95))
  end

  def test_a_gem_under_the_floor_is_named_with_its_score_and_the_floor
    faults = CriticGem.new(name: "usage-rb", paths: []).faults(report(94.99), floor: 95)

    assert_equal(["usage-rb: the score is 94.99, under 95."], faults)
  end

  def test_a_fault_of_a_file_is_named_with_its_gem
    faults = CriticGem.new(name: "proof", paths: []).faults(report(99.0, rating: "B"), floor: 95)

    assert_equal(["proof: lib/a.rb is rated B."], faults)
  end

  def test_the_score_comes_before_the_faults_of_files
    faults = CriticGem.new(name: "proof", paths: []).faults(report(90.0, rating: "C"), floor: 95)

    assert_equal(["proof: the score is 90.0, under 95.", "proof: lib/a.rb is rated C."], faults)
  end
end
