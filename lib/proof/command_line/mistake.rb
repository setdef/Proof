# frozen_string_literal: true

module Proof
  module CommandLine
    class Mistake < StandardError
      STATUS = 2
      public_constant(:STATUS)

      def initialize(text)
        super("proof: #{text}")
      end
    end
  end
end
