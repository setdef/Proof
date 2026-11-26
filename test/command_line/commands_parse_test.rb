# frozen_string_literal: true

require_relative("../support/command_line_helper")
require_relative("../test_helper")

# Checks the arguments and flags of every command but `proof run`.
class CommandLineCommandsParseTest < Minitest::Test
  include CommandLineHelper

  # proof.usage.kdl: `cmd "watch"` takes a run and `--json`.
  def test_watch_takes_a_run_and_json
    assert_equal(CL::WatchCommand.new(run: "m3d8q", json: true), command("watch", "m3d8q", "--json"))
  end

  # proof.usage.kdl: `cmd "logs"` takes a run, `--tail`, and `--no-pager`.
  def test_logs_takes_a_run_a_tail_and_no_pager
    words = %w[logs m3d8q --tail 100 --no-pager]

    assert_equal(CL::LogsCommand.new(run: "m3d8q", tail: "100", no_pager: true), command(*words))
  end

  # proof.usage.kdl: `arg "<run>..."` on cancel takes many.
  def test_cancel_takes_every_run_given
    assert_equal(CL::CancelCommand.new(runs: %w[a b c]), command("cancel", "a", "b", "c"))
  end

  # proof.usage.kdl: `download` takes a run, then `[pattern]...`, and `-o --output`, and `--json`.
  def test_download_takes_a_run_patterns_and_an_output
    words = ["download", "m3d8q", "pkg/*.gem", "-o", "dist", "b", "--json"]
    expected = CL::DownloadCommand.new(run: "m3d8q", patterns: ["pkg/*.gem", "b"], output: "dist", json: true)

    assert_equal(expected, command(*words))
  end

  # proof.usage.kdl: `status` takes `--json`.
  def test_status_takes_json
    assert_equal(CL::StatusCommand.new(json: true), command("status", "--json"))
  end

  # proof.usage.kdl: `verify` takes `--json`.
  def test_verify_takes_json
    assert_equal(CL::VerifyCommand.new(json: true), command("verify", "--json"))
  end

  # proof.usage.kdl: `runner list` takes `--json`.
  def test_runner_list_takes_json
    assert_equal(CL::RunnerListCommand.new(json: true), command("runner", "list", "--json"))
  end

  # proof.usage.kdl: `login` takes a server and `--code-file`.
  def test_login_takes_a_server_and_a_code_file
    words = %w[login server.home.arpa --code-file code]

    assert_equal(CL::LoginCommand.new(server: "server.home.arpa", code_file: "code"), command(*words))
  end

  # proof.usage.kdl: `logout` takes nothing.
  def test_logout_takes_nothing
    assert_equal(CL::LogoutCommand.new, command("logout"))
  end

  # proof.usage.kdl: `runner start` and `hook uninstall` take nothing.
  def test_runner_start_and_hook_uninstall_take_nothing
    assert_equal(CL::RunnerStartCommand.new, command("runner", "start"))
    assert_equal(CL::HookUninstallCommand.new, command("hook", "uninstall"))
  end

  # proof.usage.kdl: `skill install` takes `--to`.
  def test_skill_install_takes_a_folder
    words = ["skill", "install", "--to", "~/.claude/skills"]

    assert_equal(CL::SkillInstallCommand.new(to: "~/.claude/skills"), command(*words))
  end

  # proof.usage.kdl: `server setup` and `server upgrade` take `-n --dry-run`.
  def test_server_setup_and_upgrade_take_a_dry_run
    assert_equal(CL::ServerSetupCommand.new(dry_run: true), command("server", "setup", "-n"))
    assert_equal(CL::ServerUpgradeCommand.new(dry_run: true), command("server", "upgrade", "--dry-run"))
  end

  # proof.usage.kdl: `server uninstall` takes `-f --force`.
  def test_server_uninstall_takes_force
    assert_equal(CL::ServerUninstallCommand.new(force: true), command("server", "uninstall", "-f"))
  end

  # proof.usage.kdl: `runner setup` takes a server, `--name`, `--desktop`, `--no-wsl`, and `-n --dry-run`.
  def test_runner_setup_takes_a_server_and_its_flags
    words = %w[runner setup server.home.arpa --name nuc --desktop --no-wsl -n]
    expected = CL::RunnerSetupCommand.new(
      server: "server.home.arpa",
      name: "nuc",
      desktop: true,
      no_wsl: true,
      dry_run: true
    )

    assert_equal(expected, command(*words))
  end

  # proof.usage.kdl: `arg "[code]"` on runner approve is optional: without it, Proof lists the runners waiting.
  def test_runner_approve_takes_a_code_or_none
    assert_equal(CL::RunnerApproveCommand.new(code: "XK7P-42MQ"), command("runner", "approve", "XK7P-42MQ"))
    assert_equal(CL::RunnerApproveCommand.new(code: nil), command("runner", "approve"))
  end

  # proof.usage.kdl: `runner stop` and `runner uninstall` take `-f --force`.
  def test_runner_stop_and_uninstall_take_force
    assert_equal(CL::RunnerStopCommand.new(force: true), command("runner", "stop", "-f"))
    assert_equal(CL::RunnerUninstallCommand.new(force: false), command("runner", "uninstall"))
  end

  # proof.usage.kdl: `runner revoke` takes a name and `-f --force`.
  def test_runner_revoke_takes_a_name_and_force
    assert_equal(
      CL::RunnerRevokeCommand.new(name: "nuc-linux", force: true),
      command("runner", "revoke", "nuc-linux", "-f")
    )
  end

  # proof.usage.kdl: `hook install` takes a task and `-f --force`.
  def test_hook_install_takes_a_task_and_force
    assert_equal(CL::HookInstallCommand.new(task: "test", force: true), command("hook", "install", "test", "--force"))
  end
end
