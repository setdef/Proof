# frozen_string_literal: true

require "kdl"
require_relative("located_node")

module Proof
  module KdlLines
    module Output
      # The grammar builds every node, value, and document through the module it is given, so this module is KDL
      # with its Node replaced. The grammar reaches Node through the module, so the constant is public.
      include ::KDL

      Node = LocatedNode
      public_constant(:Node)
    end
  end
end
