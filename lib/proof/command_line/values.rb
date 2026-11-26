# frozen_string_literal: true

module Proof
  module CommandLine
    class Values
      def initialize
        @flags = {}
        @words = {}
        @help = false
        @tasks = nil
      end

      def switch(name)
        @flags[name] = true
      end

      def replace(name, text)
        @flags[name] = text
      end

      def append(name, text)
        @flags[name] = list(name) + [text]
      end

      def assign(name, words)
        @words[name] = words
      end

      def assign_tasks(tasks)
        @tasks = tasks
      end

      def extras
        @tasks ? { tasks: @tasks } : {}
      end

      def ask_for_help
        @help = true
      end

      def help?
        @help
      end

      def flag?(name)
        @flags.key?(name)
      end

      def given?(member)
        member.start_with?("--") ? flag?(member.delete_prefix("--")) : !list(member).empty?
      end

      def text(name)
        found = @flags[name]
        found if found.is_a?(String)
      end

      def first(name)
        list(name).first
      end

      def list(name)
        found = @flags[name] || @words[name]
        found.is_a?(Array) ? found : []
      end
    end
  end
end
