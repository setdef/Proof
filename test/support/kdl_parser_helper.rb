# frozen_string_literal: true

require_relative("../test_helper")

# Short names for the tests of the reader of KDL text: the lines of a text's nodes.
module KdlParserHelper
  PATH = ".config/proof.kdl"
  public_constant(:PATH)

  # Every node's name and line, parents before their children, in the order the text has them.
  def lines(text)
    flatten(Proof::KdlParser.parse(text, path: PATH, error: Proof::ProjectFileError))
  end

  def flatten(nodes)
    nodes.flat_map { |node| [[node.name, node.line]] + flatten(node.children) }
  end
end
