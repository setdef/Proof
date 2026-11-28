# frozen_string_literal: true

require_relative("test_helper")
require_relative("xdg_environment")

# Issue 131: the server keeps its state in `$XDG_DATA_HOME/proof/server` and reads the pool file from
# `$XDG_CONFIG_HOME/proof/pool.kdl`, and under `~/.local/share` and `~/.config` when a variable isn't set, as
# architecture.md says.
class ServerPathsTest < Minitest::Test
  include XdgEnvironment

  HOME = "/home/proof"
  private_constant(:HOME)

  def test_the_folder_is_under_the_homes_local_share_when_no_variable_is_set
    assert_equal("/home/proof/.local/share/proof/server", Proof::Server::Paths.find(HOME).folder)
  end

  def test_the_pool_file_is_under_the_homes_config_when_no_variable_is_set
    assert_equal("/home/proof/.config/proof/pool.kdl", Proof::Server::Paths.find(HOME).pool_file)
  end

  def test_the_folder_is_under_xdg_data_home_when_it_names_an_absolute_path
    with_xdg(data: "/srv/data") { assert_equal("/srv/data/proof/server", Proof::Server::Paths.find(HOME).folder) }
  end

  def test_the_pool_file_is_under_xdg_config_home_when_it_names_an_absolute_path
    with_xdg(config: "/srv/config") do
      assert_equal("/srv/config/proof/pool.kdl", Proof::Server::Paths.find(HOME).pool_file)
    end
  end

  def test_each_variable_moves_only_its_own_path
    with_xdg(data: "/srv/data") do
      assert_equal("/home/proof/.config/proof/pool.kdl", Proof::Server::Paths.find(HOME).pool_file)
    end
  end

  # The specification says to ignore an empty variable.
  def test_an_empty_variable_is_ignored
    with_xdg(data: "", config: "") do
      paths = Proof::Server::Paths.find(HOME)

      assert_defaults(paths)
    end
  end

  # The specification says to ignore a variable that doesn't name an absolute path.
  def test_a_relative_variable_is_ignored
    with_xdg(data: "data", config: "~/config") do
      paths = Proof::Server::Paths.find(HOME)

      assert_defaults(paths)
    end
  end

  def test_a_trailing_slash_on_a_variable_makes_no_difference
    with_xdg(data: "/srv/data/") { assert_equal("/srv/data/proof/server", Proof::Server::Paths.find(HOME).folder) }
  end

  private def assert_defaults(paths)
    assert_equal("/home/proof/.local/share/proof/server", paths.folder)
    assert_equal("/home/proof/.config/proof/pool.kdl", paths.pool_file)
  end
end
