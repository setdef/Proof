# frozen_string_literal: true

module Proof
  module CommandLine
    class Builder
      CLASSES = {
        ["run"] => RunCommand,
        ["watch"] => WatchCommand,
        ["logs"] => LogsCommand,
        ["cancel"] => CancelCommand,
        ["download"] => DownloadCommand,
        ["status"] => StatusCommand,
        ["login"] => LoginCommand,
        ["logout"] => LogoutCommand,
        ["verify"] => VerifyCommand,
        %w[skill install] => SkillInstallCommand,
        %w[server setup] => ServerSetupCommand,
        %w[server upgrade] => ServerUpgradeCommand,
        %w[server uninstall] => ServerUninstallCommand,
        %w[runner setup] => RunnerSetupCommand,
        %w[runner approve] => RunnerApproveCommand,
        %w[runner start] => RunnerStartCommand,
        %w[runner stop] => RunnerStopCommand,
        %w[runner list] => RunnerListCommand,
        %w[runner revoke] => RunnerRevokeCommand,
        %w[runner uninstall] => RunnerUninstallCommand,
        %w[hook install] => HookInstallCommand,
        %w[hook uninstall] => HookUninstallCommand,
      }.freeze
      private_constant(:CLASSES)

      def initialize(spec, line)
        @lineage = spec.commands.at(line.command.path)
        @line = line
        @command = @lineage.command
      end

      def parsed
        Parsed.new(global:, command: value)
      end

      private def global
        Attributes.new(@lineage.global_flags, [], @line).build(GlobalFlags, {})
      end

      private def value
        Attributes.new(@command.own_flags, @command.args, @line).build(CLASSES[@command.path], tasks)
      end

      private def tasks
        return {} unless @command.path == ["run"]

        before, after = run_words
        return { tasks: Tasks.read(before, after, @command), script_words: [] } unless @line.given?("script")

        # usage 7.4.1 can't say that a task and --script exclude each other once a script takes words after --,
        # so Proof's rule is here.
        raise(Mistake, Messages.new(@command).task_with_script) unless before.empty?

        { tasks: [], script_words: after }
      end

      private def run_words
        words = @command.args.flat_map { |arg| @line.words(arg.name) }
        after = @line.separated
        # Every word after the first `--` is an argument's, so the arguments' words before it are the others.
        [words.first(words.size - after.size), after]
      end
    end
  end
end
