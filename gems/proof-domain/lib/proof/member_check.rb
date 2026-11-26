# frozen_string_literal: true

module Proof
  module MemberCheck
    def self.problem(rules, members)
      members.each do |member, value|
        message, rule = rules[member]
        return format(message, value) unless rule.call(value)
      end
      nil
    end

    def self.named?(value)
      value.is_a?(String) && !value.empty?
    end

    def self.names?(value)
      value.is_a?(Array) && !value.empty? && value.all? { |name| named?(name) } && value.uniq.size == value.size
    end

    def self.whole?(value, minimum)
      value.is_a?(Integer) && value >= minimum
    end

    def self.flag?(value)
      [true, false].include?(value)
    end
  end
  private_constant(:MemberCheck)
end
