# frozen_string_literal: true

require_relative("label")
require_relative("listing")

module Proof
  # steep:ignore:start
  class LabelSet < Data.define(:labels)
    # steep:ignore:end
    def self.of(*names)
      new(labels: names.map { |name| Label.new(name:) })
    end

    def initialize(labels:)
      found = Listing.set(labels, Label, 0)
      raise(InvalidLabelSetError, format("a set of labels holds only labels, not %p", labels)) unless found

      super(labels: found)
    end

    def |(other)
      LabelSet.new(labels: labels | other.labels)
    end

    def offers_every_label_of?(required)
      required.labels.subset?(labels)
    end
  end
end
