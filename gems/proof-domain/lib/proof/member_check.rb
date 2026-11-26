# frozen_string_literal: true

require_relative("name")

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
      Name.valid?(value)
    end

    def self.names?(value)
      value.is_a?(Array) && !value.empty? && value.all? { |name| named?(name) } && value.uniq.size == value.size
    end

    def self.distinct_names?(value)
      # Names compare as Proof::Label does, with String#casecmp?, so two that differ only in case are one name.
      names?(value) && value.combination(2).none? { |one, other| one.casecmp?(other) }
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
