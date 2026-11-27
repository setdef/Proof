# frozen_string_literal: true

require "open3"
require "rbconfig"

# What the tests of what loading Proof brings in share: the files a fresh Ruby process loads for some code, and the gems
# those files belong to.
#
# Each check runs in a fresh Ruby process, which starts with the same files loaded as any other. A process that already
# ran the tests has loaded the gems itself and would hide the difference.
module LoadedGems
  LIB = File.expand_path("../lib", __dir__)
  # A gem's folder in a path, such as `rom-sql` in `.../gems/rom-sql-3.7.0/lib/rom/sql.rb`. The name stops at the first
  # slash, because a system's gem folder holds a `gems` folder of its own: `.../gems/4.1.0/gems/rom-sql-3.7.0/`.
  GEM_FOLDER = %r{/gems/([^/]+)-\d[^/]*/}
  private_constant(:LIB, :GEM_FOLDER)

  # The files that +code+ added to a fresh Ruby process, with Proof's lib folder on the load path.
  def loaded_by(code)
    out, err, status = Open3.capture3(RbConfig.ruby, "-I", LIB, "-e", code)

    assert_predicate(status, :success?, err)
    assert_empty(err)
    out.lines.map(&:chomp)
  end

  # The names among +names+ of the gems whose folders hold any of +paths+, in the order of +paths+.
  def gems_in(paths, names)
    folders = paths.filter_map { |path| path[GEM_FOLDER, 1] }
    folders & names
  end
end
