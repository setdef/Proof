# frozen_string_literal: true

require_relative("fence")
require_relative("skip")

module DocExamples
  # A fenced block in a list of lines: the line that opens the fence, and the
  # line that ends it. A fence that nothing ends runs to the end of the lines.
  class Span
    attr_reader :start

    # The block that a fence at index +start+ of +lines+ may open. Check
    # +opens?+ before you use it.
    def initialize(lines, start)
      @lines = lines
      @start = start
      @fence = Fence.new(lines[start].to_s)
    end

    # Whether a fence opens at the start.
    def opens?
      @fence.opens?
    end

    # The language of the fence.
    def language
      @fence.language
    end

    # The index of the line that ends the fence, or the number of lines when
    # nothing does.
    def finish
      count = @lines.size
      ((@start + 1)...count).find { |index| @fence.closes?(@lines[index].to_s) } || count
    end

    # The lines inside the fence, each with a newline and without the indent
    # of the fence.
    def code
      pad = " " * @fence.indent
      inside = @lines.slice(@start + 1, finish - @start - 1).to_a
      inside.map { |line| "#{line.delete_prefix(pad)}\n" }
        .join
    end

    # The reason in the skip marker before the fence, or nil when none is there.
    def skip_reason
      Skip.reason(@lines, @start)
    end

    # @dynamic start
  end
end
