# frozen_string_literal: true

module Proof
  # steep:ignore:start
  module CommandLine
    # steep:ignore:end
    # steep:ignore:start
    class Phrases
      # steep:ignore:end
      def self.alternatives(names)
        count = names.size
        return names.first.to_s if count == 1

        "#{names.first(count - 1).join(', ')}#{',' if count > 2} or #{names.last}"
      end

      def self.did_you_mean(suggestions)
        suggestions.empty? ? "" : " Did you mean #{alternatives(suggestions)}?"
      end

      def self.member(name)
        name.start_with?("-") ? name : "a #{name}"
      end

      attr_reader :command, :kind, :home

      def initialize(path)
        nested = !path.empty?
        @command = ["proof", *path].join(" ")
        @kind = nested ? "subcommand" : "command"
        @home = nested ? " of #{@command}" : ""
      end

      private def usage
        ending("To see its usage, run:")
      end

      private def ending(lead)
        "#{lead} #{command} --help"
      end
    end
    private_constant(:Phrases)
  end
end
