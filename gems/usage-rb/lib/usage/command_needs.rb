# frozen_string_literal: true

module Usage
  class CommandNeeds
    def initialize(position, values)
      @position = position
      @values = values
    end

    def parsed
      # usage stops at help, and asks nothing more of the command line.
      return @values.parsed(command, {}) if @values.help?

      args = Binding.new(@position, @values.arguments).to_h
      subcommand
      met(Given.new(scope: @position.scope, values: @values, args:))
      @values.parsed(command, args)
    end

    private def command
      @position.command
    end

    private def subcommand
      @position.refuse(&:missing_subcommand) if command.subcommand_required?
    end

    private def met(given)
      groups(given)
      requirements(given)
    end

    private def groups(given)
      group = command.groups.find { |each| each.required? && !given.gives_any?(each.names) }
      @position.refuse { |said| said.missing_member(group) } if group
    end

    private def requirements(given)
      flag = @position.flags.find { |each| given.unmet(each) }
      @position.refuse { |said| said.missing_requirement(flag, given.unmet(flag).to_s) } if flag
    end
  end
end
