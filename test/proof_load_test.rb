# frozen_string_literal: true

require_relative("test_helper")
require "open3"
require "rbconfig"

# Checks what loading Proof brings in. The command starts on Ruby's standard library alone, so the `kdl` gem and the
# gems it loads wait until a project file's KDL is read, and ROM, Sequel, and SQLite wait until a store of runs is built.
#
# Each check runs in a fresh Ruby process, which starts with the same files loaded as any other. A process that already
# ran the tests has loaded `kdl` itself and would hide the difference.
class ProofLoadTest < Minitest::Test
  LIB = File.expand_path("../lib", __dir__)
  KDL_GEMS = %w[kdl bigdecimal simpleidn base64 racc].freeze
  # ROM, rom-sql, Sequel, the `sqlite3` gem, and the gems they load.
  STORE_GEMS = %w[
    rom
    rom-core
    rom-changeset
    rom-repository
    rom-sql
    sequel
    sqlite3
    transproc
    dry-core
    dry-types
    dry-struct
    dry-configurable
    dry-inflector
    dry-initializer
    dry-logic
    concurrent-ruby
    ice_nine
    zeitwerk
  ].freeze
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
  OPEN_STORE = <<~RUBY
    require("tmpdir")
    before = $LOADED_FEATURES.dup
    require("proof")
    Dir.mktmpdir { |folder| Proof::Sqlite::Runs.new(path: File.join(folder, "runs.db")).close }
    puts($LOADED_FEATURES - before)
  RUBY
  private_constant(:LIB, :KDL_GEMS, :STORE_GEMS, :REQUIRE_PROOF, :PARSE, :OPEN_STORE)

  # Architecture, "Command line": "no KDL read at run time and no `kdl` gem, so the command starts on Ruby's standard
  # library alone." Requiring Proof loads none of the gems that `kdl` brings.
  def test_requiring_proof_loads_no_kdl_gem
    assert_empty(kdl_gems_in(loaded_by(REQUIRE_PROOF)))
  end

  # Architecture, "Storage": ROM, Sequel, and SQLite load when a store of runs is built, so a command that opens no
  # store starts on Ruby's standard library alone.
  def test_requiring_proof_loads_no_storage_gem
    assert_empty(storage_gems_in(loaded_by(REQUIRE_PROOF)))
  end

  # Building a store of runs loads the gems it is made of, and works on a process that hasn't loaded them before.
  def test_building_a_store_loads_the_storage_gems
    loaded = storage_gems_in(loaded_by(OPEN_STORE))

    assert_equal(%w[rom rom-sql sequel sqlite3], loaded & %w[rom rom-sql sequel sqlite3])
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

  # The names among +paths+ that are a gem the store loads, found by the gem's folder, because `sequel` and `sqlite3`
  # name files in other gems too.
  def storage_gems_in(paths)
    folders = paths.filter_map { |path| path[%r{/gems/(.+?)-\d[^/]*/}, 1] }
    folders & STORE_GEMS
  end
end
