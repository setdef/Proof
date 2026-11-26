# frozen_string_literal: true

require_relative("test_helper")
require "open3"
require "rbconfig"

# Checks what loading Proof brings in. The command starts on Ruby's standard library alone, so the `kdl` gem and the
# gems it loads wait until a project file's KDL is read.
#
# Each check runs in a fresh Ruby process, which starts with the same files loaded as any other. A process that already
# ran the tests has loaded `kdl` itself and would hide the difference.
class ProofLoadTest < Minitest::Test
  LIB = File.expand_path("../lib", __dir__)
  KDL_GEMS = %w[kdl bigdecimal simpleidn base64 racc].freeze
  REQUIRE_PROOF = <<~RUBY
    before = $LOADED_FEATURES.dup
    require("proof")
    puts($LOADED_FEATURES - before)
  RUBY
  PARSE = <<~RUBY
    before = $LOADED_FEATURES.dup
    require("proof")
    Proof::KdlParser.parse("task test\\n", path: ".config/proof.kdl")
    puts($LOADED_FEATURES - before)
  RUBY
  private_constant(:LIB, :KDL_GEMS, :REQUIRE_PROOF, :PARSE)

  # Architecture, "Command line": "no KDL read at run time and no `kdl` gem, so the command starts on Ruby's standard
  # library alone." Requiring Proof loads none of the gems that `kdl` brings.
  def test_requiring_proof_loads_no_kdl_gem
    assert_empty(kdl_gems_in(loaded_by(REQUIRE_PROOF)))
  end

  # Architecture, "KDL": `Proof::KdlParser` is the code that touches the gem, so the first parse loads it, and the
  # parse works on a process that hasn't loaded the gem before.
  def test_the_first_parse_loads_the_kdl_gem
    assert_includes(kdl_gems_in(loaded_by(PARSE)), "kdl")
  end

  # The files that +code+ added to a fresh Ruby process, with Proof's lib folder on the load path.
  def loaded_by(code)
    out, err, status = Open3.capture3(RbConfig.ruby, "-I", LIB, "-e", code)

    assert_predicate(status, :success?, err)
    assert_empty(err)
    out.lines.map(&:chomp)
  end

  # The names among +paths+ that are the `kdl` gem or a gem it loads.
  def kdl_gems_in(paths)
    names = paths.to_set { |path| File.basename(path, ".*") }
    KDL_GEMS.select { |name| names.include?(name) }
  end
end
