# frozen_string_literal: true

require_relative("kdl_lines/lined_parser")
require_relative("kdl_lines/output")
require_relative("kdl_syntax_reason")

module Proof
  class KdlParser
    def self.parse(text, path:)
      new(path:).parse(text)
    end

    def initialize(path:)
      @path = path
    end

    def parse(text)
      parser = KdlLines::LinedParser.new(output_module: KdlLines::Output, parse_types: false)
      parser.parse(text).nodes.map(&:to_kdl_node)
    rescue KDL::Error => e
      raise(ProjectFileError.new(path: @path, line: e.line, reason: KdlSyntaxReason.new(error: e).to_s))
    end
  end
end
