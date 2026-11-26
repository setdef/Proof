# frozen_string_literal: true

require_relative("phrases")

module Proof
  module CommandLine
    class WordMessages < Phrases
      def unknown_command(word, suggestions)
        "#{word} isn't a #{kind}#{home}.#{Phrases.did_you_mean(suggestions)} #{ending("To list the #{kind}s, run:")}"
      end

      def needs_subcommand(names)
        "#{command} needs a subcommand: #{Phrases.alternatives(names)}. #{ending('To list them, run:')}"
      end

      def missing_member(names)
        "#{command} needs #{Phrases.alternatives(names.map { |name| Phrases.member(name) })}. #{usage}"
      end

      def missing_argument(argument)
        "#{command} needs #{argument}. #{usage}"
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
