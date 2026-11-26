# frozen_string_literal: true

require "kdl"
require_relative("end_of_text")
require_relative("located_node")

module Proof
  module KdlLines
    class LinedParser < KDL::Parser
      ENDS_OF_NODE = %i[NEWLINE EOF SEMICOLON].freeze
      private_constant(:ENDS_OF_NODE)

      def initialize(output_module:, parse_types:)
        super
        @held = []
        @after_brace = false
      end

      private def next_token
        token = after_brace_space(@held.shift || super) { super() }
        Thread.current[LINE] = token.last.line
        @after_brace = token.first == :RBRACE
        token
      end

      private def after_brace_space(token)
        # The gem's grammar reads a space after a block's closing brace as the start of another block to skip, so a
        # space or a comment before the end of the node is an error it raises for valid KDL 2. The space says nothing
        # there, so it is dropped, and a token that isn't an end of the node is kept for the next read.
        return token unless @after_brace && token.first == :WS

        following = yield
        return following if ENDS_OF_NODE.include?(following.first)

        @held << following
        token
      end
    end
  end
end
