# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class FileError < Error
    # steep:ignore:end
    attr_reader :path, :line, :reason

    def initialize(path:, line:, reason:)
      # The class line is ignored by Steep, which doesn't count attr_reader as defining the readers that
      # the signature declares, and RuboCop rejects a method that only returns an instance variable.
      @path = path
      @line = line
      @reason = reason
      super("#{[path, line].compact.join(':')}: #{reason}")
    end
  end
end
