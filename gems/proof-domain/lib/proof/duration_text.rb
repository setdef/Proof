# frozen_string_literal: true

module Proof
  module DurationText
    FORM = /\A(?<number>[1-9]\d*)(?<unit>[smh])\z/
    SECONDS = { s: 1, m: 60, h: 3600 }.freeze
    private_constant(:FORM, :SECONDS)

    def self.seconds(text)
      match = (text.is_a?(String) && text.ascii_only?) ? FORM.match(text) : nil
      match && (Integer(match[:number], 10) * SECONDS[match[:unit].to_sym])
    end
  end
  private_constant(:DurationText)
end
