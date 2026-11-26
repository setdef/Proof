# frozen_string_literal: true

require_relative("test_helper")

# Checks that a key holding the wrong type is refused, naming the key and the type it should have.
class UsageSpecTypesTest < Minitest::Test
  include UsageTestHelper

  # A name is a string.
  def test_a_text_of_another_type_is_refused
    assert_equal("the program has bin that isn't a string", refusal('{"bin": 3}'))
  end

  # A flag's names are a list of strings.
  def test_a_list_of_another_type_is_refused
    assert_equal(
      "flag v of the program has short that isn't a list",
      refusal('{"cmd": {"flags": [{"name": "v", "short": "v"}]}}')
    )
    assert_equal(
      "flag v of the program has short that isn't a list of strings",
      refusal('{"cmd": {"flags": [{"name": "v", "short": [1]}]}}')
    )
  end

  # A setting such as `var` is true or false.
  def test_a_yes_or_no_of_another_type_is_refused
    assert_equal(
      "flag v of the program has var that isn't true or false",
      refusal('{"cmd": {"flags": [{"name": "v", "var": "yes"}]}}')
    )
  end

  # An exit status is a whole number, and it can't be left out.
  def test_a_status_that_is_not_a_whole_number_is_refused
    message = "an exit code of the program has code that isn't a whole number"

    assert_equal([message, message], [refusal('{"exit_codes": [{"code": "2"}]}'), refusal('{"exit_codes": [{}]}')])
  end

  # A command is an object.
  def test_an_object_of_another_type_is_refused
    assert_equal("the program has cmd that isn't an object", refusal('{"cmd": []}'))
  end

  # A command's flags are a list of objects.
  def test_a_list_of_objects_of_another_type_is_refused
    assert_equal("the program has flags that isn't a list of objects", refusal('{"cmd": {"flags": [1]}}'))
  end

  # A command's subcommands are objects, by name.
  def test_an_object_of_objects_of_another_type_is_refused
    assert_equal(
      "the program has subcommands that isn't an object of objects",
      refusal('{"cmd": {"subcommands": {"a": 1}}}')
    )
  end
end
