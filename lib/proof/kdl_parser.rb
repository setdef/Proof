# frozen_string_literal: true

require_relative("kdl_lines/lined_parser")
require_relative("kdl_lines/output")
require_relative("kdl_syntax_reason")

module Proof
  class KdlParser
    NOT_UTF8 = "this is not valid KDL 2: the text is not valid UTF-8"
    ENDS_TOO_SOON = "this is not valid KDL 2: the text ends in the middle of a string"
    private_constant(:NOT_UTF8, :ENDS_TOO_SOON)

    def self.parse(text, path:)
      new(path:).parse(text)
    end

    def initialize(path:)
      @path = path
    end

    def parse(text)
      parser = KdlLines::LinedParser.new(output_module: KdlLines::Output, parse_types: false)
      parser.parse(utf8_of(text)).nodes.map(&:to_kdl_node)
    rescue KDL::Error => e
      raise(ProjectFileError.new(path: @path, line: e.line, reason: KdlSyntaxReason.new(error: e).to_s))
    rescue TypeError
      # The gem's tokenizer fails with a TypeError, and not its own error, for a string that a backslash ends the
      # text in, so the mistake is at the end of the text.
      raise(ProjectFileError.new(path: @path, line: text.lines.size, reason: ENDS_TOO_SOON))
    end

    private def utf8_of(text)
      # KDL is UTF-8, whatever encoding the caller's string has, and the gem raises an ArgumentError, with no line,
      # for a byte that isn't UTF-8.
      decoded = text.dup.force_encoding(Encoding::UTF_8)
      broken = decoded.lines.index { |line| !line.valid_encoding? }
      raise(ProjectFileError.new(path: @path, line: broken + 1, reason: NOT_UTF8)) if broken

      decoded
    end
  end
end
