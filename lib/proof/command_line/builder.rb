# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
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

      def initialize(spec, command, values)
        @spec = spec
        @command = command
        @values = values
      end

      def invocation
        Invocation.new(global:, command:)
      end

      private def global
        # steep:ignore:start
        GlobalFlags.new(**Attributes.new(@spec.root.global_flags, [], @values).to_h)
        # steep:ignore:end
      end

      private def command
        klass = CLASSES.fetch(@command.path)
        attributes = Attributes.new(@command.own_flags, @command.args, @values).to_h.merge(@values.extras)
        # steep:ignore:start
        klass.new(**attributes.slice(*klass.members))
        # steep:ignore:end
      end
    end
    private_constant(:Builder)
  end
end
