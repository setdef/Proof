# frozen_string_literal: true

require_relative("kdl_syntax_reason")

module Proof
  module KdlLines
    # The adapters load the `kdl` gem and the gems it loads, so they load on the first parse, and a command that reads
    # no KDL starts on Ruby's standard library alone.
    autoload(:LinedParser, File.join(__dir__.to_s, "kdl_lines/lined_parser.rb"))
    autoload(:Output, File.join(__dir__.to_s, "kdl_lines/output.rb"))
  end

  class KdlParser
    NOT_UTF8 = "this is not valid KDL 2: the text is not valid UTF-8"
    ENDS_TOO_SOON = "this is not valid KDL 2: the text ends in the middle of a string"
    private_constant(:NOT_UTF8, :ENDS_TOO_SOON)

    def self.parse(text, path:, error: ProjectFileError)
      new(path:, error:).parse(text)
    end

    def initialize(path:, error: ProjectFileError)
      @path = path
      @error = error
    end

    def parse(text)
      parser = KdlLines::LinedParser.new(output_module: KdlLines::Output, parse_types: false)
      parser.parse(utf8_of(text)).nodes.map(&:to_kdl_node)
    rescue KDL::Error => e
      raise(@error.new(path: @path, line: e.line, reason: syntax_reason(e)))
    rescue TypeError
      # The gem's tokenizer fails with a TypeError, and not its own error, for a string that a backslash ends the
      # text in, so the mistake is at the end of the text.
      raise(@error.new(path: @path, line: text.lines.size, reason: ENDS_TOO_SOON))
    end

    private def syntax_reason(error)
      KdlSyntaxReason.new(error:, quoted_as: @error::QUOTED_AS).to_s
    end

    private def utf8_of(text)
      # KDL is UTF-8, whatever encoding the caller's string has, and the gem raises an ArgumentError, with no line,
      # for a byte that isn't UTF-8.
      decoded = text.dup.force_encoding(Encoding::UTF_8)
      broken = decoded.lines.index { |line| !line.valid_encoding? }
      raise(@error.new(path: @path, line: broken + 1, reason: NOT_UTF8)) if broken

      decoded
    end
  end
end
