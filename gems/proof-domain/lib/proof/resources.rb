# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class Resources < Data.define(:cpus, :megabytes)
    # steep:ignore:end
    MEMORY_MESSAGE = "memory is a size: a number, whole or decimal, an optional space, and MB, GB, TB, " \
      "MiB, GiB, or TiB in any case, such as \"512MB\", \"8 GB\", \"1.5gib\", or \"0.5TB\", not %p"
    private_constant(:MEMORY_MESSAGE)

    def self.request(cpus:, memory:)
      raise(InvalidResourcesError, format("cpus is a whole number from 1, not %p", cpus)) unless
        cpus.is_a?(Integer) && cpus >= 1

      megabytes = SizeText.megabytes(memory)
      raise(InvalidResourcesError, format(MEMORY_MESSAGE, memory)) unless megabytes

      new(cpus:, megabytes:)
    end

    def initialize(cpus:, megabytes:)
      raise(InvalidResourcesError, format("cpus is a whole number from 0, not %p", cpus)) unless
        cpus.is_a?(Integer) && cpus >= 0
      raise(InvalidResourcesError, format("megabytes is a whole number from 0, not %p", megabytes)) unless
        megabytes.is_a?(Integer) && megabytes >= 0

      super
    end

    def fits_within?(available)
      cpus <= available.cpus && megabytes <= available.megabytes
    end
  end
end
