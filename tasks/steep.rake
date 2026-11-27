# frozen_string_literal: true

require_relative("steep_loads")

namespace :steep do
  desc "Fail when a Steep target fails to load, so Steep checks none of its files"
  task :loads do
    failures = SteepLoads.failures(".")
    next puts("Every Steep target loads.") if failures.empty?

    abort(<<~MESSAGE)
      #{failures.join("\n")}
      Steep checks none of the files of a target that fails to load, and reports no error for it.
      Steep loads every target's signatures into every other target, so add the library to the list in the Steepfile.
    MESSAGE
  end
end

# The steep task is defined in tasks/shared/steep.rake, which loads first.
Rake::Task[:steep].enhance(%w[steep:loads])
