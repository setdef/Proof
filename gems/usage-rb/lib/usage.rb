# frozen_string_literal: true

require_relative("usage/arg")
require_relative("usage/arg_format")
require_relative("usage/choices")
require_relative("usage/command")
require_relative("usage/command_page")
require_relative("usage/command_tree")
require_relative("usage/example")
require_relative("usage/example_format")
require_relative("usage/exit_code")
require_relative("usage/exit_code_format")
require_relative("usage/flag")
require_relative("usage/flag_format")
require_relative("usage/group")
require_relative("usage/group_format")
require_relative("usage/help")
require_relative("usage/keys")
require_relative("usage/layout")
require_relative("usage/lists")
require_relative("usage/page")
require_relative("usage/program_page")
require_relative("usage/reader")
require_relative("usage/spec")
require_relative("usage/spec_error")
require_relative("usage/usage_line")
require_relative("usage/version")

module Usage
  private_constant(
    :ArgFormat,
    :CommandPage,
    :ExampleFormat,
    :ExitCodeFormat,
    :FlagFormat,
    :GroupFormat,
    :Keys,
    :Layout,
    :Lists,
    :Page,
    :ProgramPage,
    :Reader,
    :UsageLine
  )
end
