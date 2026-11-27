# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    # steep:ignore:start
    class Queued < Data.define(:at, :position, :os, :labels, :resources)
      # steep:ignore:end
      include Fact

      def initialize(at:, position:, os:, labels:, resources:)
        unless labels.is_a?(LabelSet)
          raise(InvalidFactError, format("a queued run's labels are a set of labels, not %p", labels))
        end

        super(
          at:, position: Fact.count(position, 1, "a queue position is a whole number from 1, not %p"),
          os: operating_systems(os), labels:, resources: requested(resources))
      end

      private def operating_systems(given)
        found = Listing.set(given, OS, 1)
        return found if found

        raise(InvalidFactError, format("a queued run's os is one or more operating systems, not %p", given))
      end

      private def requested(given)
        return given if given.is_a?(Resources) && given.cpus >= 1

        raise(InvalidFactError, format("a queued run requests resources with at least 1 CPU, not %p", given))
      end
    end
  end
end
