# frozen_string_literal: true

require_relative("loaded_gems")
require_relative("test_helper")

# Checks what loading Proof brings in. The command starts on Ruby's standard library alone, so the `kdl` gem and the
# gems it loads wait until a project file's KDL is read, and ROM, Sequel, and SQLite wait until a store of runs is built.
class ProofLoadTest < Minitest::Test
  include LoadedGems

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
    Proof::KdlParser.parse("task test\\n", path: ".config/proof.kdl", error: Proof::ProjectFileError)
    puts($LOADED_FEATURES - before)
  RUBY
  OPEN_STORE = <<~RUBY
    require("tmpdir")
    before = $LOADED_FEATURES.dup
    require("proof")
    Dir.mktmpdir { |folder| Proof::Sqlite::Runs.new(path: File.join(folder, "runs.db")).close }
    puts($LOADED_FEATURES - before)
  RUBY
  private_constant(:KDL_GEMS, :STORE_GEMS, :REQUIRE_PROOF, :PARSE, :OPEN_STORE)

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

  # The check above finds a gem in either layout, because a check that finds none passes whether or not the store loads
  # its gems.
  def test_a_gem_is_found_in_a_bundle_folder_and_in_a_system_gem_folder
    paths = %w[
      /work/vendor/bundle/ruby/4.1.0/gems/dry-core-1.2.0/lib/dry/core.rb
      /opt/ruby/lib/ruby/gems/4.1.0/gems/rom-sql-3.7.0/lib/rom/sql.rb
      /opt/ruby/lib/ruby/gems/4.1.0/gems/sqlite3-2.10.2-x86_64-linux-gnu/lib/sqlite3.rb
      /opt/ruby/lib/ruby/gems/4.1.0/gems/kdl-2.2.0/lib/kdl.rb
      /opt/ruby/lib/ruby/4.1.0/json.rb
    ]

    assert_equal(%w[dry-core rom-sql sqlite3], storage_gems_in(paths))
  end

  # The names among +paths+ that are the `kdl` gem or a gem it loads.
  def kdl_gems_in(paths)
    names = paths.to_set { |path| File.basename(path, ".*") }
    KDL_GEMS.select { |name| names.include?(name) }
  end

  # The names among +paths+ that are a gem the store loads, found by the gem's folder, because `sequel` and `sqlite3`
  # name files in other gems too.
  def storage_gems_in(paths)
    gems_in(paths, STORE_GEMS)
  end
end
