# frozen_string_literal: true

require_relative("command_line/cancel_command")
require_relative("command_line/download_command")
require_relative("command_line/global_flags")
require_relative("command_line/help_request")
require_relative("command_line/hook_install_command")
require_relative("command_line/hook_uninstall_command")
require_relative("command_line/invocation")
require_relative("command_line/login_command")
require_relative("command_line/logout_command")
require_relative("command_line/logs_command")
require_relative("command_line/run_command")
require_relative("command_line/runner_approve_command")
require_relative("command_line/runner_list_command")
require_relative("command_line/runner_revoke_command")
require_relative("command_line/runner_setup_command")
require_relative("command_line/runner_start_command")
require_relative("command_line/runner_stop_command")
require_relative("command_line/runner_uninstall_command")
require_relative("command_line/server_setup_command")
require_relative("command_line/server_uninstall_command")
require_relative("command_line/server_upgrade_command")
require_relative("command_line/skill_install_command")
require_relative("command_line/spec")
require_relative("command_line/status_command")
require_relative("command_line/task_words")
require_relative("command_line/verify_command")
require_relative("command_line/watch_command")

module Proof
  module CommandLine
  end
end
