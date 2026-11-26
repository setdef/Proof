# frozen_string_literal: true

require_relative("test_helper")

# Checks the reader of KDL text that finds each node's line. The gem it wraps keeps no line on a node, so Proof finds
# the lines through the gem's parser, and these tests fail when a release of the gem changes how.
class KdlParserTest < Minitest::Test
  PATH = ".config/proof.kdl"
  private_constant(:PATH)

  # Every node's name and line, parents before their children, in the order the text has them.
  def lines(text)
    flatten(Proof::KdlParser.parse(text, path: PATH))
  end

  def flatten(nodes)
    nodes.flat_map { |node| [[node.name, node.line]] + flatten(node.children) }
  end

  # Project file reference, "Where Proof reads the file": the refusal names "the line", so a node has the line of its
  # name, one for each node, whatever the lines before it hold.
  def test_a_node_has_the_line_of_its_name
    text = "defaults cpus=4 {\n  os linux\n}\n\ntask test {\n  label desktop\n}\ntask docs \"x y\"\n"

    assert_equal([["defaults", 1], ["os", 2], ["task", 5], ["label", 6], ["task", 8]], lines(text))
  end

  # The same sentence, for nodes that share a line: a `;` ends a node and the next one starts on the same line.
  def test_nodes_separated_by_semicolons_share_a_line
    assert_equal([["task", 1], ["task", 1], ["task", 2]], lines("task a; task b\ntask c\n"))
  end

  # The same sentence, for children: a node inside a block has its own line, and one on the line of its parent's
  # closing brace or of a sibling has that line.
  def test_nested_nodes_have_their_own_lines
    text = "task a {\n  os linux; label gpu\n  cache \"x\"\n}\ntask b { os macos }\ntask c\n"

    assert_equal(
      [["task", 1], ["os", 2], ["label", 2], ["cache", 3], ["task", 5], ["os", 5], ["task", 6]], lines(text)
    )
  end

  # The same sentence, for a `/-` node: the grammar builds a slashdashed node and drops it, so the node after it
  # must not take its line, and neither must the children of a dropped node.
  def test_a_slashdash_node_is_skipped_and_the_next_keeps_its_line
    text = "// comment\n\n/- task skipped\ntask a\n/- task b {\n  os linux\n}\ntask c\n"

    assert_equal([["task", 4], ["task", 8]], lines(text))
  end

  # The same sentence, for a `/-` child inside a block.
  def test_a_slashdash_child_is_skipped
    assert_equal([["task", 1], ["label", 3]], lines("task a {\n  /- os linux\n  label gpu\n}\n"))
  end

  # The same sentence, for a node whose entries continue on later lines with `\`: its line is where its name is.
  def test_a_node_whose_entries_continue_has_the_line_of_its_name
    assert_equal([["task", 1], ["task", 3]], lines("task a \\\n  memory=\"1GB\"\ntask b\n"))
  end

  # The same sentence, for a node with no entries, which the parser reduces after the line break that follows it,
  # and for the last node of a text that has no line break at its end.
  def test_a_node_with_no_entries_has_its_own_line
    assert_equal([["a", 1], ["b", 2], ["c", 4]], lines("a\nb\n\nc"))
  end

  # The same sentence, for a node with a type annotation and for a name in quotes.
  def test_a_typed_node_and_a_quoted_name_have_their_lines
    assert_equal([["a", 1], ["b c", 2]], lines("(t)a\n\"b c\" x\n"))
  end

  # The same sentence, for line breaks that are a carriage return and a line feed.
  def test_a_text_with_carriage_returns_counts_lines
    assert_equal([["a", 1], ["b", 2], ["c", 3]], lines("a\r\nb\r\nc\r\n"))
  end

  # The text of two parses in turn: the line of the first doesn't carry into the second.
  def test_a_second_parse_starts_again_at_line_one
    lines("\n\n\na")

    assert_equal([["b", 1]], lines("b"))
  end

  # The command design, "The interface and the project file": "The project file is KDL 2, and a file that isn't valid
  # KDL 2 is refused". This text is valid KDL 1 and not KDL 2, which the gem reads as KDL 1 when asked for no version.
  def test_a_text_that_is_kdl_1_is_refused
    error = assert_raises(Proof::ProjectFileError) { lines("task a true\n") }

    assert_equal(1, error.line)
  end

  # The same page: the document says it is KDL 1, so the KDL 2 reader refuses it, as the gem's own marker means.
  def test_a_text_that_says_it_is_kdl_1_is_refused
    error = assert_raises(Proof::ProjectFileError) { lines("/- kdl-version 1\ntask a\n") }

    assert_equal(
      ".config/proof.kdl:1: this is not valid KDL 2: version mismatch, document specified v1, " \
        "but this is a v2 parser at column 1",
      error.message
    )
  end

  # Project file reference, "Where Proof reads the file": the refusal names "the file, the line, and what's wrong".
  def test_a_syntax_mistake_names_the_file_the_line_and_the_reason
    error = assert_raises(Proof::ProjectFileError) { lines("task a\ntask b {\n  os linux\n") }

    assert_equal(".config/proof.kdl:4: this is not valid KDL 2: unexpected $end :EOF at column 1", error.message)
  end

  # Project file reference, "Mistakes Proof catches, and one it can't": "KDL also needs quotes around a value that
  # starts with a digit and continues with letters", so the refusal of `memory=8GB` says so.
  def test_an_unquoted_size_is_refused_with_the_quotes_that_work
    error = assert_raises(Proof::ProjectFileError) { lines("task package memory=8GB\n") }

    assert_equal(
      ".config/proof.kdl:1: this is not valid KDL 2: unexpected IDENT \"GB\" at column 22. " \
        "If a value starts with a digit and continues with letters, put it in quotes, as in memory=\"8GB\"",
      error.message
    )
  end

  # The error keeps what its message says, so a caller can show each part.
  def test_the_error_keeps_its_parts
    error = assert_raises(Proof::ProjectFileError) { lines("a }\n") }

    assert_equal(
      [PATH, 1, "this is not valid KDL 2: unexpected RBRACE \"}\" at column 3"],
      [error.path, error.line, error.reason]
    )
  end

  # The values of a node are Ruby's: the text, the whole number, the decimal, `#true`, `#false`, and `#null`.
  def test_values_are_ruby_values
    node = Proof::KdlParser.parse("a \"x\" 3 1.5 #true #false #null k=\"v\" n=2\n", path: PATH).first

    assert_equal(["x", 3, 1.5, true, false, nil], node.arguments)
    assert_equal([%w[k v], ["n", 2]], node.properties.to_a)
  end

  # A value that has a type annotation is read as the value, not converted to the annotation's type.
  def test_a_type_annotation_converts_nothing
    node = Proof::KdlParser.parse("a (date)\"2026-11-26\" (i8)5\n", path: PATH).first

    assert_equal(["2026-11-26", 5], node.arguments)
  end

  # Only the text of the file is read: an empty file and a file of comments have no nodes.
  def test_a_text_with_no_nodes_has_none
    assert_equal([[], []], [Proof::KdlParser.parse("", path: PATH), Proof::KdlParser.parse("// none\n", path: PATH)])
  end

  # A node says all it says in its arguments when it has no property and no child, which is how a child of a
  # task entry such as `os linux macos` is written.
  def test_a_node_with_only_arguments_says_so
    only, with_property, with_child = ["os linux macos\n", "os linux a=1\n", "os linux {\n  a\n}\n"].map do |text|
      Proof::KdlParser.parse(text, path: PATH).first.arguments_only?
    end

    assert_equal([true, false, false], [only, with_property, with_child])
  end
end
