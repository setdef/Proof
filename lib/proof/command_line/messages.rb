# frozen_string_literal: true

require_relative("phrases")

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
    class Messages < Phrases
      def unknown_flag(switch, suggestions)
        "#{switch} isn't a flag of #{command}.#{Phrases.did_you_mean(suggestions)} #{ending('To list the flags, run:')}"
      end

      def missing_value(switch)
        "#{switch} needs a value. #{usage}"
      end

      def flag_for_value(switch, value)
        "#{switch} needs a value, and #{value} looks like a flag. #{usage}"
      end

      def needless_value(switch)
        "#{switch} takes no value. #{usage}"
      end

      def bad_choice(switch, value, choices)
        "#{switch} takes one of #{Phrases.alternatives(choices)}, not #{value}. #{usage}"
      end

      def missing_requirement(switch, required)
        "#{switch} needs #{required}. #{usage}"
      end
    end
    private_constant(:Messages)
  end
end
