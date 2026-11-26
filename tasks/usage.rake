# frozen_string_literal: true

require_relative("usage_references")

namespace :usage do
  desc "Lint the CLI spec"
  task :lint do
    sh("usage lint proof.usage.kdl")
  end

  desc "Fail when a generated CLI reference differs from what the spec generates"
  task :references do
    stale = UsageReferences.stale
    next puts("The CLI references match the spec.") if stale.empty?

    abort(<<~MESSAGE)
      Out of date: #{stale.join(', ')}
      Never edit them by hand. Regenerate both from proof.usage.kdl:
        #{UsageReferences.regenerate_commands.join("\n  ")}
    MESSAGE
  end
end
