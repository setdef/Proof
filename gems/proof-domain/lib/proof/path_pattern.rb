# frozen_string_literal: true

require_relative("path_text")

module Proof
  class PathPattern < Data.define(:path)
    MESSAGE = "a path is relative to the workspace's root, so it is not empty, doesn't start with /, " \
      "and doesn't contain .., such as \"pkg/*.gem\" or \"tmp/engine/build\", not %p"
    private_constant(:MESSAGE)

    def initialize(path:)
      raise(InvalidPathPatternError, format(MESSAGE, path)) unless PathText.relative?(path)

      # relative? has found a String, which Steep can't know.
      text = path #: String
      super(path: -text)
    end

    # @dynamic path
  end
end
