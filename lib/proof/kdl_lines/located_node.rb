# frozen_string_literal: true

require "kdl"

module Proof
  module KdlLines
    LINE = :proof_kdl_line
    private_constant(:LINE)

    # steep:ignore:start
    class LocatedNode < KDL::Node
      # steep:ignore:end
      attr_reader :line

      def initialize(name)
        # The class line is ignored by Steep, which doesn't count attr_reader as defining the reader that the
        # signature declares, and RuboCop rejects a method that only returns an instance variable.
        #
        # The grammar calls Node.new with the name alone, once the parser has read the name's token, so the line
        # of the token the parser read last is the node's line. The value is fiber-local, so a parse in another
        # fiber or thread can't change it.
        @line = Thread.current[LINE]
        super
      end

      def to_kdl_node
        KdlNode.new(
          name:,
          arguments: arguments.map(&:value),
          properties: properties.transform_values(&:value),
          children: children.map(&:to_kdl_node),
          line:
        )
      end
    end
  end
end
