# frozen_string_literal: true

require_relative("support/pool_file_reader_helper")

# Checks the mistakes in the shape of `share`, which takes the properties `cpus` and `memory`.
class PoolFileReaderShareTest < Minitest::Test
  include PoolFileReaderHelper

  USAGE = "share cpus=2 memory=\"4GB\""
  MISTAKES = [
    ["defaults {\n  share \"4GB\"\n}\n", 2, "a \"share\" node takes no arguments, as in #{USAGE}, and this one has 1"],
    ["defaults {\n  share cpus=2\n}\n", 2, "a \"share\" node needs the property \"memory\""],
    ["defaults {\n  share memory=\"4GB\"\n}\n", 2, "a \"share\" node needs the property \"cpus\""],
    [
      "defaults {\n  share cpus=2 memory=\"4GB\" gpus=1\n}\n",
      2,
      "a \"share\" node has no property \"gpus\". Its properties are cpus and memory",
    ],
    [
      "defaults {\n  share cpus=2 memory=\"4GB\" {\n    x\n  }\n}\n",
      3,
      "a \"share\" node has no child \"x\". It has no children",
    ],
  ].freeze
  private_constant(:USAGE, :MISTAKES)

  # Pool file reference, "`host`": `share cpus=N memory="SIZE"` has properties and no arguments, no block, and both
  # properties, so each of those is refused, at the line of the `share` node or of its first child.
  def test_a_share_that_is_not_cpus_and_memory_is_refused
    assert_refusals(MISTAKES)
  end
end
