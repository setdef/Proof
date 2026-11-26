# frozen_string_literal: true

require_relative("duration")
require_relative("member_check")

module Proof
  # steep:ignore:start
  class RepositoryEntry < Data.define(:name, :url, :credentials_file, :branches, :tasks, :poll)
    # steep:ignore:end
    PATH_OR_NOTHING = -> (value) { value.nil? || MemberCheck.named?(value) }
    NAMES = MemberCheck.method(:names?)
    RULES = {
      name: ["a repository's name is a name, not %p", MemberCheck.method(:named?)],
      url: ["a repository's url is a name, not %p", MemberCheck.method(:named?)],
      credentials_file: ["a repository's credentials file is a path or nothing, not %p", PATH_OR_NOTHING],
      branches: ["a repository's branches are one or more branch names that differ, not %p", NAMES],
      tasks: ["a repository's tasks are one or more task names that differ, not %p", NAMES],
      poll: ["a repository's poll is a duration, not %p", Duration.method(:===)],
    }.freeze
    private_constant(:PATH_OR_NOTHING, :NAMES, :RULES)

    def initialize(name:, url:, branches:, tasks:, **optional)
      # The credentials file and the poll arrive as one hash, since six keywords make a parameter list longer than
      # RuboCop accepts.
      given = { credentials_file: nil, poll: Duration.new(seconds: 60), **optional }
      problem = MemberCheck.problem(RULES, { name:, url:, branches:, tasks:, **given })
      raise(InvalidRepositoryEntryError, problem) if problem

      super(name: -name, url:, branches: branches.dup.freeze, tasks: tasks.dup.freeze, **given)
    end
  end
end
