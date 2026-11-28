# frozen_string_literal: true

module Usage
  class Messages
    def initialize(command)
      @command = command
      @place = Place.command(command.path).name
    end

    def unknown_flag(word, _switches)
      "#{@place} has no flag #{word}"
    end

    def missing_value(switch)
      "#{switch} of #{@place} needs a value"
    end

    def flag_for_value(flag, word)
      "#{named(flag)} needs a value, and #{word} looks like a flag"
    end

    def needless_value(switch)
      "#{switch} of #{@place} takes no value"
    end

    def bad_choice(flag, value)
      "#{named(flag)} takes one of #{flag.choices.values.join(', ')}, not #{value}"
    end

    def missing_requirement(flag, required)
      "#{named(flag)} needs #{required}"
    end

    def unknown_command(word)
      "#{@place} has no subcommand #{word}"
    end

    def missing_subcommand
      "#{@place} needs a subcommand: #{@command.subcommand_names.join(', ')}"
    end

    def missing_member(group)
      "#{@place} needs one of #{group.names.join(', ')}"
    end

    def missing_argument(arg)
      "#{@place} needs #{arg}"
    end

    def extra_word(word)
      "#{@place} takes no word #{word}"
    end

    private def named(flag)
      "#{flag.switches.last} of #{@place}"
    end
  end
end
