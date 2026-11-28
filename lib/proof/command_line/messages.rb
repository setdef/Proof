# frozen_string_literal: true

require "usage"
require_relative("phrases")

module Proof
  module CommandLine
    class Messages < Usage::Messages
      include Phrases

      def initialize(command)
        super
        @path = command.path
        @subcommands = command.subcommand_names
      end

      def unknown_flag(word, switches)
        switch = FlagName.typed(word, switches)
        nearest = Phrases.did_you_mean(switch, switches)
        "#{switch} isn't a flag of #{command}.#{nearest} #{ending('To list the flags, run:')}"
      end

      def missing_value(switch)
        "#{switch} needs a value. #{usage}"
      end

      def flag_for_value(flag, value)
        "#{Phrases.flag(flag)} needs a value, and #{value} looks like a flag. #{usage}"
      end

      def needless_value(switch)
        "#{switch} takes no value. #{usage}"
      end

      def bad_choice(flag, value)
        "#{Phrases.flag(flag)} takes one of #{Phrases.alternatives(flag.choices.values)}, not #{value}. #{usage}"
      end

      def missing_requirement(flag, required)
        "#{Phrases.flag(flag)} needs #{required}. #{usage}"
      end

      def unknown_command(word)
        nearest = Phrases.did_you_mean(word, @subcommands)
        "#{word} isn't a #{kind}#{home}.#{nearest} #{ending("To list the #{kind}s, run:")}"
      end

      def missing_subcommand
        "#{command} needs a subcommand: #{Phrases.alternatives(@subcommands)}. #{ending('To list them, run:')}"
      end

      def missing_member(group)
        "#{command} needs #{Phrases.alternatives(group.names.map { |name| Phrases.member(name) })}. #{usage}"
      end

      def task_with_script
        "#{Phrases.member('task')} and #{Phrases.member('--script')} can't go together; give one. #{usage}"
      end

      def missing_argument(arg)
        "#{command} needs #{arg}. #{usage}"
      end

      def extra_word(word)
        "#{word} isn't a word #{command} takes. #{usage}"
      end

      def leading_tasks_marker
        "::: needs a task before it, as in proof run lint ::: test. #{usage}"
      end

      def dangling_tasks_marker
        "::: needs a task name after it, as in proof run lint ::: test. #{usage}"
      end
    end
  end
end
