# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class LabelSet < Data.define(:labels)
    # steep:ignore:end
    def self.of(*names)
      new(labels: names.map { |name| Label.new(name:) })
    end

    def initialize(labels:)
      unless [Array, Set].any? { |kind| labels.is_a?(kind) } && labels.all?(Label)
        raise(InvalidLabelSetError, format("a set of labels holds only labels, not %p", labels))
      end

      super(labels: Set.new(labels).freeze)
    end

    def offers_every_label_of?(required)
      required.labels.subset?(labels)
    end
  end
end
