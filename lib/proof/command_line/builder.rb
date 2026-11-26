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

      def initialize(spec, command, values)
        @spec = spec
        @command = command
        @values = values
      end

      def invocation
        Invocation.new(global:, command:)
      end

      private def global
        construct(GlobalFlags, @spec.root.global_flags, [])
      end

      private def command
        construct(CLASSES[@command.path], @command.own_flags, @command.args)
      end

      private def construct(klass, flags, args)
        attributes = Attributes.new(flags, args, @values).to_h.merge(@values.extras)
        # Steep can't check a keyword splat against the members that Data.define made, so it can't see that
        # each class takes exactly the attributes the spec's flags and arguments give it. The commands_test
        # file checks that for every command.
        # steep:ignore:start
        klass.new(**attributes.slice(*klass.members))
        # steep:ignore:end
      end
    end
  end
end
