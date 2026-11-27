# frozen_string_literal: true

require_relative("name")

module Proof
  module MemberCheck
    def self.rules(table)
      table.freeze
    end

    def self.defaults(table)
      table.freeze
    end

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
      # Two names that differ only in case are one name, as Name.same? finds. names? has found an Array of names,
      # which Steep can't know.
      # steep:ignore:start
      names?(value) && value.combination(2).none? { |one, other| Name.same?(one, other) }
      # steep:ignore:end
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
