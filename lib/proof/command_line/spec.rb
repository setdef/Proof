# frozen_string_literal: true

require "usage"

module Proof
  module CommandLine
    module Spec
      PATH = File.join(File.dirname(__FILE__), "spec.json")
      public_constant(:PATH)

      def self.load
        Usage::Spec.read(File.read(PATH))
      end
    end
  end
end
