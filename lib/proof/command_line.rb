# frozen_string_literal: true

require_relative("command_line/arg_slot")
require_relative("command_line/attributes")
require_relative("command_line/branch")
require_relative("command_line/cancel_command")
require_relative("command_line/checks")
require_relative("command_line/columns")
require_relative("command_line/download_command")
require_relative("command_line/example_block")
require_relative("command_line/failure")
require_relative("command_line/flag_slot")
require_relative("command_line/global_flags")
require_relative("command_line/help")
require_relative("command_line/help_request")
require_relative("command_line/hook_install_command")
require_relative("command_line/hook_uninstall_command")
require_relative("command_line/invocation")
require_relative("command_line/leaf")
require_relative("command_line/login_command")
require_relative("command_line/logout_command")
require_relative("command_line/logs_command")
require_relative("command_line/messages")
require_relative("command_line/mistake")
require_relative("command_line/options")
require_relative("command_line/parser")
require_relative("command_line/phrases")
require_relative("command_line/positionals")
require_relative("command_line/profiles")
require_relative("command_line/resolver")
require_relative("command_line/rows")
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
require_relative("command_line/suggestions")
require_relative("command_line/switch")
require_relative("command_line/tables")
require_relative("command_line/task_words")
require_relative("command_line/tasks")
require_relative("command_line/tokens")
require_relative("command_line/values")
require_relative("command_line/verify_command")
require_relative("command_line/watch_command")
require_relative("command_line/word_messages")

# Builder names every command class when it loads, so it loads after them.
require_relative("command_line/builder")

module Proof
  module CommandLine
    def self.parse(argv)
      Parser.new(Spec.load).parse(argv)
    end

    def self.help(path)
      spec = Spec.load
      Help.new(spec, spec.command(path) || spec.root).text
    end
  end
end
