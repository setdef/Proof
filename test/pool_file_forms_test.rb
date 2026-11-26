# frozen_string_literal: true

require_relative("test_helper")

# Checks that the form of each node of the pool file is what the page's reference sections list for it.
class PoolFileFormsTest < Minitest::Test
  SETTINGS = %i[budget keep-free share active-for withhold].freeze
  private_constant(:SETTINGS)

  # The form of the node with this name.
  def form(name)
    Proof::PoolFileForms[name]
  end

  # Pool file reference, "`server`", "`retention`", and "`limits`": each takes properties, `port` for the server,
  # `runs`, `output`, and `artifacts` for retention, and `output` and `artifacts` for limits, and no arguments and no
  # children.
  def test_the_nodes_with_properties_list_them
    assert_equal(
      [%i[port], %i[runs output artifacts], %i[output artifacts]],
      %i[server retention limits].map { |name| form(name).properties }
    )
    shapes = %i[server retention limits].map { |name| [form(name).arguments, form(name).children] }

    assert_equal([[0..0, []]] * 3, shapes)
  end

  # Pool file reference, "`defaults`": "It takes the same children as a `host`, except `runner`", and `host NAME` has
  # one argument, its name, and the child `runner RUNNER...`.
  def test_defaults_and_host_list_their_children
    assert_equal(
      [SETTINGS, [:runner, *SETTINGS], 0..0, 1..1],
      [form(:defaults).children, form(:host).children, form(:defaults).arguments, form(:host).arguments]
    )
  end

  # Pool file reference, "`host`", table: `runner` is "Required", so a host needs one, and
  # the page's complete example gives two `runner` children, so a runner and a host may be given more than once.
  def test_a_host_needs_a_runner_and_a_host_and_a_runner_may_be_repeated
    assert_equal(
      [[:runner], true, true, false],
      [form(:host).needs, form(:host).repeatable, form(:runner).repeatable, form(:budget).repeatable]
    )
  end

  # Pool file reference, "`host`": `budget "SIZE"`, `keep-free "SIZE"`, and `active-for "DURATION"` take one argument,
  # `runner RUNNER...` and `withhold LABEL...` take one or more, and `share cpus=N memory="SIZE"` takes properties and
  # needs both.
  def test_each_child_takes_the_arguments_the_page_writes
    assert_equal(
      [1..1, 1..1, 1..1, 1.., 1.., 0..0],
      %i[budget keep-free active-for runner withhold share].map { |name| form(name).arguments }
    )
    assert_equal([%i[cpus memory]] * 2, [form(:share).properties, form(:share).required])
  end

  # Pool file reference, "`repository`": `repository NAME url="URL"` has one argument, its name, and the property `url`,
  # which is "Required", and the children `credentials-file`, `branch`, `task`, and `poll`, where `branch` and `task`
  # are "Required" too.
  def test_a_repository_needs_a_url_a_branch_and_a_task
    repository = form(:repository)

    assert_equal(
      [1..1, %i[url], %i[url], %i[credentials-file branch task poll], %i[branch task]],
      [repository.arguments, repository.properties, repository.required, repository.children, repository.needs]
    )
  end

  # The same sections: `task TASK...` is given in several nodes in the complete example, and `branch BRANCH...` is
  # given once, so `task` may be repeated and `branch` may not.
  def test_a_task_may_be_repeated_and_a_branch_may_not
    arguments = %i[branch task poll].map { |name| form(name).arguments }

    assert_equal([[1.., 1.., 1..1], true, false], [arguments, form(:task).repeatable, form(:branch).repeatable])
  end

  # A name that the page doesn't list has no form.
  def test_a_name_the_page_does_not_list_has_no_form
    assert_nil(form(:cluster))
  end
end
