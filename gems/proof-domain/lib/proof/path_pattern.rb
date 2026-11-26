# frozen_string_literal: true

require_relative("path_text")

module Proof
  # steep:ignore:start
  class PathPattern < Data.define(:path)
    # steep:ignore:end
    MESSAGE = "a path is relative to the workspace's root, so it is not empty, doesn't start with /, " \
      "and has no folder named .., such as \"pkg/*.gem\" or \"tmp/engine/build\", not %p"
    private_constant(:MESSAGE)

    def initialize(path:)
      raise(InvalidPathPatternError, format(MESSAGE, path)) unless PathText.relative?(path)

      super(path: -path)
    end
  end
end
