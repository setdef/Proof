# frozen_string_literal: true

module Proof
  module DurationText
    SECONDS = { d: 86_400, h: 3600, m: 60, s: 1 }.freeze
    private_constant(:SECONDS)

    def self.seconds(text, units)
      match = (text.is_a?(String) && text.ascii_only?) ? form(units).match(text) : nil
      match && (Integer(match[:number], 10) * SECONDS[match[:unit].to_sym])
    end

    def self.form(units)
      Regexp.new("\\A(?<number>[1-9]\\d*)(?<unit>[#{units.join}])\\z")
    end
    private_class_method(:form)
  end
  private_constant(:DurationText)
end
