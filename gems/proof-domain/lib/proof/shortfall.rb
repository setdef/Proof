# frozen_string_literal: true

module Proof
  class Shortfall < Data.define(:resource, :could_have, :requested)
    RESOURCES = %i[cpus memory].freeze
    public_constant(:RESOURCES)

    def self.of(ever, requested)
      both = [new(:cpus, ever.cpus, requested.cpus), new(:memory, ever.megabytes, requested.megabytes)]
      both.select(&:short?)
    end

    def self.size(megabytes)
      (megabytes % 1024).zero? ? "#{megabytes / 1024} GB" : "#{megabytes} MB"
    end

    def initialize(resource:, could_have:, requested:)
      raise(InvalidShortfallError, format("a shortfall is of cpus or memory, not %p", resource)) unless
        RESOURCES.include?(resource)

      amounts = [could_have, requested]
      raise(InvalidShortfallError, format("a shortfall's amounts are whole numbers from 0, not %p", amounts)) unless
        amounts.all? { |amount| amount.is_a?(Integer) && amount >= 0 }

      super
    end

    def short?
      could_have < requested
    end

    def fraction
      Rational(could_have, requested)
    end

    def to_s
      return "#{could_have} of the #{requested} #{(requested == 1) ? 'CPU' : 'CPUs'}" if resource == :cpus

      "#{Shortfall.size(could_have)} of the #{Shortfall.size(requested)}"
    end
  end
end
