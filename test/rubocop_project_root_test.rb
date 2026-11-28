# frozen_string_literal: true

require_relative("test_helper")
require "open3"
require "rbconfig"
require "tmpdir"
require "yaml"

# Checks that RuboCop takes the repository as its project root, wherever the checkout sits. RuboCop's own search takes
# the topmost Gemfile above the working directory, so a checkout below another folder with a Gemfile gets that folder.
class RubocopProjectRootTest < Minitest::Test
  # Makes a checkout below a folder with a Gemfile, the checkout holding the helper, and returns both paths.
  def checkout_below_gemfile(folder)
    outer = File.realpath(folder)
    checkout = File.join(outer, "checkout")
    FileUtils.mkdir_p(File.join(checkout, "tasks"))
    FileUtils.touch([File.join(outer, "Gemfile"), File.join(checkout, "Gemfile")])
    FileUtils.cp(File.join(repository, helper), File.join(checkout, helper))
    [outer, checkout]
  end

  # Yields the folder, the checkout, and the root RuboCop has after it loads +files+, a list of paths in the checkout.
  def with_root_found(*files)
    Dir.mktmpdir("rubocop-project-root-test") do |folder|
      outer, checkout = checkout_below_gemfile(folder)
      yield(outer, checkout, project_root(checkout, files.map { |file| File.join(checkout, file) }))
    end
  end

  def project_root(checkout, files)
    program = 'require "rubocop"; ARGV.each { |file| load(file) }; puts RuboCop::ConfigFinder.project_root'
    found, status = Open3.capture2(RbConfig.ruby, "-e", program, *files, chdir: checkout)

    assert_predicate(status, :success?)
    found.chomp
  end

  def repository
    File.expand_path("..", __dir__)
  end

  def helper
    "tasks/rubocop_project_root.rb"
  end

  def test_rubocop_alone_takes_the_topmost_gemfile_as_the_root
    with_root_found do |outer, _checkout, found|
      assert_equal(outer, found)
    end
  end

  def test_loading_the_helper_makes_the_checkout_the_root
    with_root_found(helper) do |_outer, checkout, found|
      assert_equal(checkout, found)
    end
  end

  def test_the_rubocop_configuration_loads_the_helper
    required = YAML.safe_load_file(File.join(repository, ".rubocop.yml"))["require"]

    assert_includes(required, "./#{helper}")
  end
end
