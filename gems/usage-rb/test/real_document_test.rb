# frozen_string_literal: true

require_relative("test_helper")

# Checks the gem against a document as `usage generate json` writes it, with every default it fills in, for a spec of
# a small program.
class UsageRealDocumentTest < Minitest::Test
  include UsageTestHelper

  # The JSON that usage 7.4.1 writes for a spec of a small program: a global flag, a command with a flag and an
  # argument, an example, and an exit status. Only the defaults in it matter here.
  DOCUMENT = File.read(File.expand_path("real_document.json", __dir__))
  private_constant(:DOCUMENT)

  # Every key usage writes by default is one the gem accepts, so a spec with nothing unusual reads.
  def test_a_document_with_every_default_usage_writes_is_read
    spec = read(DOCUMENT)

    assert_equal(["todo", "Keep a list", ["add"]], [spec.bin, spec.about, spec.commands.root.subcommands.map(&:name)])
    assert_equal(["quiet"], spec.commands.at([]).global_flags.map(&:name))
  end

  # The defaults are read as the program's help shows them.
  def test_the_help_of_a_document_shows_what_the_spec_says
    help = Usage::Help.new(read(DOCUMENT)).text(["add"]).lines(chomp: true)

    assert_includes(help, "  --tag <tag>  Tag it (one of home, work)")
    assert_includes(help, "  -q, --quiet  Print less")
  end
end
