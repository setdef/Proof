# frozen_string_literal: true

module Proof
  class FileRefusal
    def initialize(path:, error:, messages:)
      @path = path
      @error = error
      @messages = messages
    end

    def checking(node)
      yield
    rescue Error => e
      # The block builds domain values and nothing else, so what it raises is what the domain refuses.
      refuse(node, e.message)
    end

    private def say(node, key, *values)
      refuse(node, format(@messages[key], *values))
    end

    private def refuse(node, reason)
      raise(@error.new(path: @path, line: node.line, reason:))
    end
  end
end
