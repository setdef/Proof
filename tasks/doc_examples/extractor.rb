# frozen_string_literal: true

require_relative("block")
require_relative("comments")
require_relative("spans")

module DocExamples
  # Finds the fenced +ruby+ blocks in a Markdown page, and in the RDoc
  # comments of an +.rbs+ file, which RDoc reads as Markdown.
  #
  # Only a fence whose language is +ruby+ yields a block, and nothing inside
  # any other fence does. A skip marker directly before a fence marks its
  # block as skipped.
  module Extractor
    # The blocks in a file's text, from its text and its path. A path that
    # ends in +.rbs+ names a file of RDoc comments, and any other a Markdown
    # page.
    def self.blocks(text, path)
      path.end_with?(".rbs") ? rbs(text, path) : markdown(text, path)
    end

    # The blocks in the text of a Markdown page. +first_line+ is the line of
    # the file where the text starts.
    def self.markdown(text, path, first_line = 1)
      spans = Spans.scan(text.lines(chomp: true)).select { |span| span.language == "ruby" }
      spans.map { |span| block(span, path, first_line) }
    end

    # The blocks in the comments of an +.rbs+ file. Each run of comment lines
    # is a Markdown text of its own, so a fence never spans two comments.
    def self.rbs(text, path)
      Comments.runs(text.lines(chomp: true)).flat_map do |first_line, lines|
        markdown(lines.join("\n"), path, first_line)
      end
    end

    # The block that +span+ holds, in the file at +path+, for a text that
    # starts at line +first_line+ of it.
    def self.block(span, path, first_line)
      Block.new(path:, line: first_line + span.start + 1, code: span.code, skip_reason: span.skip_reason)
    end
    private_class_method(:block)
  end
end
