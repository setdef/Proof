# frozen_string_literal: true

require "kdl"
require_relative("located_node")

module Proof
  module KdlLines
    class LinedParser < KDL::Parser
      private def next_token
        token = super
        Thread.current[LINE] = token.last.line
        token
      end
    end
  end
end
