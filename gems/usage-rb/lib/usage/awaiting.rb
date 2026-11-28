# frozen_string_literal: true

module Usage
  class Awaiting
    def initialize(line)
      @line = line
      @switches = []
    end

    def reach(switch)
      # usage reads the letters up to help.
      return if @line.help?

      switch.takes_value? ? @switches << switch : switch.read(@line)
    end

    def given
      return if @switches.empty?

      @line.help? ? lacking : bind
    end

    private def lacking
      # usage reads help before it asks the next word for the letters it has passed.
      @line.refuse { |said| said.missing_value(@switches.last.typed) }
    end

    private def bind
      # usage gives the next word to the last letter that takes a value, and an empty value to those before it, last to
      # first.
      @switches.reverse.each_with_index { |switch, index| (index.zero? ? switch : switch.emptied).read(@line) }
    end
  end
end
