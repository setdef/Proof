# frozen_string_literal: true

require_relative("duration")
require_relative("member_check")
require_relative("name")

module Proof
  # steep:ignore:start
  class RepositoryEntry < Data.define(:name, :url, :credentials_file, :branches, :tasks, :poll)
    # steep:ignore:end
    PATH_OR_NOTHING = -> (value) { value.nil? || MemberCheck.named?(value) }
    NAMES = MemberCheck.method(:names?)
    RULES = MemberCheck.rules(
      name: [Name.message("a repository's name", "lota"), MemberCheck.method(:named?)],
      url: [Name.message("a repository's url", "https://github.com/setdef/Lota.git"), MemberCheck.method(:named?)],
      credentials_file: [
        "a repository's credentials file is #{Name::TEXT}, such as ~/.config/proof/credentials/lota, or nothing, " \
          "not %p",
        PATH_OR_NOTHING,
      ],
      branches: [
        "a repository's branches are one or more branch names that differ, each #{Name::TEXT}, " \
          "such as [\"trunk\"], not %p",
        NAMES,
      ],
      tasks: [
        "a repository's tasks are one or more task names that differ, each #{Name::TEXT}, " \
          "such as [\"test\"], not %p",
        NAMES,
      ],
      poll: ["a repository's poll is a duration, not %p", Duration.method(:===)]
    )
    private_constant(:PATH_OR_NOTHING, :NAMES, :RULES)

    def initialize(name:, url:, branches:, tasks:, **optional)
      # The credentials file and the poll arrive as one hash, since six keywords make a parameter list longer than
      # RuboCop accepts.
      given = { credentials_file: nil, poll: Duration.new(seconds: 60), **optional }
      problem = MemberCheck.problem(RULES, { name:, url:, branches:, tasks:, **given })
      raise(InvalidRepositoryEntryError, problem) if problem

      # problem has found a name and lists of names, which Steep can't know.
      # steep:ignore:start
      super(name: -name, url:, branches: branches.dup.freeze, tasks: tasks.dup.freeze, **given)
      # steep:ignore:end
    end
  end
end
