# frozen_string_literal: true

require_relative("../../gems/proof-domain/test/pool_file_helper")
require_relative("../test_helper")

# Short names for the tests of the reader of the pool file: read a text, and check the refusal it raises.
module PoolFileReaderHelper
  include PoolFileHelper

  PATH = "pool.kdl"
  PAGE = File.expand_path("../../doc/reference/pool-file.md", __dir__)
  public_constant(:PATH, :PAGE)

  # The pool file that this text reads as.
  def read(text)
    Proof::PoolFileReader.read(text, path: PATH)
  end

  # Checks that reading this text is refused at this line, with this reason, in a message that starts with the path.
  def assert_refused(text, line, reason)
    error = assert_raises(Proof::PoolFileError) { read(text) }

    assert_equal("#{PATH}:#{line}: #{reason}", error.message)
  end

  # Checks each refusal in a list of text, line, and reason.
  def assert_refusals(refusals)
    refusals.each { |text, line, reason| assert_refused(text, line, reason) }
  end

  # What the domain says of a value it refuses, which is what the reader says of it at the node's line. The block
  # builds the value.
  def domain_said(error_class, &)
    assert_raises(error_class, &).message
  end

  # The text of the block of this language, in the pool file page's section with this heading.
  def page_example(heading, nth = 0)
    section = File.read(PAGE)[/^#{Regexp.escape(heading)}\n(.*?)(?=^## |\z)/m, 1]
    section.scan(/^```kdl\n(.*?)^```/m)[nth].first
  end
end
