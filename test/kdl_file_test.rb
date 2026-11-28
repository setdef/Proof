# frozen_string_literal: true

require_relative("test_helper")

# Checks that a value for one KDL file builds the file's refusal from the file's description, and reads the file's text
# into its checked nodes, grouped by name, as the refusal and forms of the file say.
class KdlFileTest < Minitest::Test
  PATH = "other/pool.kdl"
  private_constant(:PATH)

  def file(messages: Proof::PoolFileRefusal::MESSAGES)
    Proof::KdlFile.new(path: PATH, error: Proof::PoolFileError, forms: Proof::PoolFileForms, messages:)
  end

  def nodes_by_name(text, file: self.file)
    file.nodes_by_name(text, refusal: file.refusal(Proof::PoolFileRefusal))
  end

  def refused(text, file: self.file)
    error = assert_raises(Proof::PoolFileError) { nodes_by_name(text, file:) }
    [error.path, error.line, error.reason]
  end

  # Pool file reference, "Mistakes Proof catches": the refusal says the file's path.
  def test_a_refusal_built_from_the_file_names_its_path
    refusal = file.refusal(Proof::PoolFileRefusal)
    node = Proof::KdlParser.parse("cluster\n", path: PATH, error: Proof::PoolFileError).first
    error = assert_raises(Proof::PoolFileError) { refusal.unknown_node(node) }

    assert_equal([PATH, 1], [error.path, error.line])
  end

  # The refusal is of the kind it is asked for, so that it has the refusals only that kind of file has.
  def test_a_refusal_is_of_the_kind_it_is_asked_for
    assert_instance_of(Proof::PoolFileRefusal, file.refusal(Proof::PoolFileRefusal))
    assert_instance_of(Proof::KdlRefusal, file.refusal(Proof::KdlRefusal))
  end

  # The refusal says the file's messages, whatever kind of refusal it is.
  def test_a_refusal_says_the_files_messages
    messages = Proof::PoolFileRefusal::MESSAGES.merge(unknown_node: "no node %<name>p here")

    assert_equal([PATH, 1, "no node \"cluster\" here"], refused("cluster\n", file: file(messages:)))
  end

  # The same page: the nodes are the file's, grouped by their names in the order the file has them, so a reader asks for
  # a kind of node by name.
  def test_the_nodes_are_grouped_by_name_in_the_order_the_file_has_them
    grouped = nodes_by_name("host a { runner x }\nserver\nhost b { runner y }\nlimits\n")

    arguments = grouped.transform_values { |nodes| nodes.flat_map(&:arguments) }

    assert_equal({ host: %w[a b], server: [], limits: [] }, arguments)
  end

  # A text with no nodes is a file with no nodes.
  def test_a_text_with_no_nodes_has_none_of_any_name
    assert_empty(nodes_by_name("// nothing\n"))
  end

  # "Mistakes Proof catches": text that isn't KDL 2 is refused at its line, in the file's error and path.
  def test_text_that_is_not_kdl_is_refused_with_the_files_error_and_path
    path, line, = refused("server\nhost =\n")

    assert_equal([PATH, 2], [path, line])
  end

  # The same bullet, for a node the file's forms don't list: the check uses the file's forms.
  def test_a_node_that_the_forms_do_not_list_is_refused_at_its_line
    path, line, reason = refused("server\ncluster\n")

    assert_equal([PATH, 2], [path, line])
    assert_match(/\Athere is no node "cluster" in a pool file\./, reason)
  end
end
