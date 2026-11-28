# frozen_string_literal: true

require_relative("../../gems/proof-domain/test/project_file_helper")
require_relative("../test_helper")

# Short names for the tests of the reader of the project file: read a text, and check the refusal it raises.
module ProjectFileReaderHelper
  include ProjectFileHelper

  PATH = ".config/proof.kdl"
  PAGE = File.expand_path("../../docs/reference/project-file.md", __dir__)
  public_constant(:PATH, :PAGE)

  # The project file that this text reads as.
  def read(text)
    Proof::ProjectFileReader.read(text, path: PATH)
  end

  # Checks that reading this text is refused at this line, with this reason, in a message that starts with the path.
  def assert_refused(text, line, reason)
    error = assert_raises(Proof::ProjectFileError) { read(text) }

    assert_equal("#{PATH}:#{line}: #{reason}", error.message)
  end

  # What the domain says of a value it refuses, which is what the reader says of it at the node's line. The block
  # builds the value.
  def domain_said(error_class, &)
    assert_raises(error_class, &).message
  end

  # The text of the block of this language, in the project file page's section with this heading.
  def page_example(heading, nth = 0)
    section = File.read(PAGE)[/^#{Regexp.escape(heading)}\n(.*?)(?=^## |\z)/m, 1]
    section.scan(/^```kdl\n(.*?)^```/m)[nth].first
  end
end
