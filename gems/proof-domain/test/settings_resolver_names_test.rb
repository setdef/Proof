# frozen_string_literal: true

require_relative("project_file_helper")
require_relative("test_helper")

# Checks the names of tasks that a run is asked for.
class SettingsResolverNamesTest < Minitest::Test
  include ProjectFileHelper

  # Project file reference, "Mistakes Proof catches": "a `task` has a blank name", so a run of a task whose name is
  # empty or only white space is refused by the entry it would look up, with the message for a task's name, so
  # `proof run " "` says what a name is.
  def test_a_blank_task_name_is_refused_with_the_message_for_a_task_name
    ["", " ", "\t"].each do |name|
      error = assert_raises(Proof::InvalidTaskEntryError, name.inspect) { resolve(Proof::ProjectFile.none, "test", name) }

      assert_equal("a task's name is #{Proof::Name::TEXT}, such as test, not #{name.inspect}", error.message)
    end
  end
end
