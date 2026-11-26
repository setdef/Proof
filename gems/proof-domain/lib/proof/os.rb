# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class OS < Data.define(:name)
    # steep:ignore:end
    NAMES = %i[linux macos windows].freeze
    public_constant(:NAMES)

    def self.all
      NAMES.map { |name| new(name:) }
    end

    def initialize(name:)
      known = NAMES.find { |candidate| candidate == name || candidate.name == name }
      raise(InvalidOSError, "an OS is one of #{NAMES.join(', ')}, not #{name.inspect}") unless known

      super(name: known)
    end

    def to_s
      name.name
    end
  end
end
