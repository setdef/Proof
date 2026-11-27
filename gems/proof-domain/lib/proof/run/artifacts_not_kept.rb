# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    class ArtifactsNotKept < Data.define(:at, :reason)
      include Fact

      REASONS = %i[no_match over_limit refused_path short_of_space].freeze
      public_constant(:REASONS)

      def initialize(at:, reason:)
        unless REASONS.include?(reason)
          raise(InvalidFactError, format("artifacts go unkept for one of #{REASONS.join(', ')}, not %p", reason))
        end

        super
      end

      def before_command?
        reason == :short_of_space
      end

      # @dynamic at, reason
    end
  end
end
