# frozen_string_literal: true

module Proof
  module CommandLine
    class Tasks
      def self.read(before, after, command)
        new(command).read(before, after)
      end

      def initialize(command)
        @messages = Messages.new(command)
        @tasks = []
        @naming = false
        @separated = false
      end

      def read(before, after)
        before.each { |word| head(word) }
        @separated = true
        finish(after)
      end

      private def finish(after)
        after.each { |word| tail(word) }
        raise(Mistake, @messages.dangling_tasks_marker) if @naming

        @tasks
      end

      private def head(word)
        return mark if word == ":::"

        (@naming || @tasks.empty?) ? begin_task(word) : add(word)
      end

      private def tail(word)
        return @separated = true if word == "--" && separator?

        head(word)
      end

      private def separator?
        !@tasks.empty? && !@separated && !@naming
      end

      private def begin_task(name)
        @tasks << TaskWords.new(name:, words: [])
        @naming = @separated = false
      end

      private def add(word)
        last = @tasks.last
        @tasks[-1] = last.with(words: [*last.words, word])
      end

      private def mark
        raise(Mistake, @messages.leading_tasks_marker) if @tasks.empty?
        raise(Mistake, @messages.dangling_tasks_marker) if @naming

        @naming = true
      end
    end
  end
end
