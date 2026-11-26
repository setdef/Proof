# frozen_string_literal: true

module Proof
  module CommandLine
    class Phrases
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

      def initialize(path)
        @path = path
      end

      def command
        ["proof", *@path].join(" ")
      end

      def kind
        @path.empty? ? "command" : "subcommand"
      end

      def home
        @path.empty? ? "" : " of #{command}"
      end

      private def usage
        ending("To see its usage, run:")
      end

      private def ending(lead)
        "#{lead} #{command} --help"
      end
    end
  end
end
