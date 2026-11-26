# frozen_string_literal: true

require_relative("usage_references")

namespace :usage do
  desc "Lint the CLI spec"
  task :lint do
    sh("usage lint proof.usage.kdl")
  end

  desc "Fail when a file generated from the CLI spec differs from what the spec generates"
  task :references do
    stale = UsageReferences.stale
    next puts("The files generated from the CLI spec match it.") if stale.empty?

    abort(<<~MESSAGE)
      Out of date: #{stale.join(', ')}
      Never edit them by hand. Regenerate them from proof.usage.kdl:
        #{UsageReferences.regenerate_commands.join("\n  ")}
    MESSAGE
  end
end
