# frozen_string_literal: true

module Proof
  module TaskCommands
    def self.valid?(commands)
      commands.is_a?(Hash) && !commands.empty? && commands.keys.all?(Name.method(:valid?)) &&
        commands.values.compact.all?(String)
    end
  end
  private_constant(:TaskCommands)
end
