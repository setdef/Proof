# frozen_string_literal: true

module DocExamples
  # The line that opens a Markdown code fence, or a line that opens none.
  #
  # A fence is three or more backticks or tildes. It ends at a fence of the
  # same character that is at least as long, so a longer fence can show a
  # shorter one. A run of backticks with a backtick after it on the same line
  # is inline code and opens nothing.
  class Fence
    PATTERN = /\A(`{3,}|~{3,})(.*)\z/
    private_constant(:PATTERN)

    attr_reader :indent

    # A fence from a +line+ of the text.
    def initialize(line)
      text = line.lstrip
      @marks = text[PATTERN, 1].to_s
      @info = text[PATTERN, 2].to_s
      @indent = line.length - text.length
    end

    # Whether the line opens a fence.
    def opens?
      !@marks.empty? && !(@marks.start_with?("`") && @info.include?("`"))
    end

    # The language, the first word after the marks.
    def language
      @info.split.first.to_s
    end

    # Whether +line+ ends the fence: marks of the same character, at least as
    # many as opened it, and nothing else.
    def closes?(line)
      stripped = line.strip
      stripped.length >= @marks.length && stripped.delete(@marks.chr).empty?
    end

    # @dynamic indent
  end
end
