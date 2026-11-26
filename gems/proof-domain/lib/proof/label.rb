# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class Label < Data.define(:name)
    # steep:ignore:end
    def initialize(name:)
      raise(InvalidLabelError, format("a label is a String with something in it, not %p", name)) unless
        name.is_a?(String) && /\S/.match?(name)

      super(name: -name)
    end

    def to_s
      name
    end
  end
end
