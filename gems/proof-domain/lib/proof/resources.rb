# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class Resources < Data.define(:cpus, :megabytes)
    # steep:ignore:end
    def self.request(cpus:, memory:)
      raise(InvalidResourcesError, format("cpus is a whole number from 1, not %p", cpus)) unless
        cpus.is_a?(Integer) && cpus >= 1
      raise(InvalidResourcesError, format("memory is a size such as \"512MB\" or \"8GB\", not %p", memory)) unless
        memory.is_a?(String) && memory.valid_encoding? && memory.match?(/\A\d+(MB|GB)\z/)

      amount = Integer(memory.delete_suffix("GB").delete_suffix("MB"), 10)
      new(cpus:, megabytes: memory.end_with?("GB") ? amount * 1024 : amount)
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
