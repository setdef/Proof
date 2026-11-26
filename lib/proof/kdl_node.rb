# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class KdlNode < Data.define(:name, :arguments, :properties, :children, :line)
    # steep:ignore:end
    def arguments_only?
      properties.empty? && children.empty?
    end
  end
end
