# frozen_string_literal: true

module Proof
  module CommandLine
    class Values
      def initialize
        @given = Set.new
        @texts = {}
        @lists = {}
        @tasks = nil
      end

      def switch(name)
        @given << name
      end

      def replace(name, text)
        @given << name
        @texts[name] = text
      end

      def append(name, text)
        @given << name
        @lists[name] = list(name) + [text]
      end

      def assign(name, words)
        @lists[name] = words
      end

      def assign_tasks(tasks)
        @tasks = tasks
      end

      def extras
        @tasks ? { tasks: @tasks } : {}
      end

      def ask_for_help
        # Every command takes -h and --help, and the spec has no flag called help, so the name is free to record it.
        switch("help")
      end

      def help?
        flag?("help")
      end

      def flag?(name)
        @given.include?(name)
      end

      def given?(member)
        member.start_with?("--") ? flag?(member.delete_prefix("--")) : !list(member).empty?
      end

      def text(name)
        @texts[name]
      end

      def first(name)
        list(name).first
      end

      def list(name)
        @lists[name] || []
      end
    end
  end
end
