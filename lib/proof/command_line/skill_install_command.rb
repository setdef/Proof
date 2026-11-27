# frozen_string_literal: true

module Proof
  module CommandLine
    class SkillInstallCommand < Data.define(:to)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic to, initialize
    end
  end
end
