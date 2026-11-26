# frozen_string_literal: true

module Proof
  module SizeText
    FORM = /\A(?<number>\d+(?:\.\d+)?) ?(?<unit>[Mm]|[Gg]|[Tt])[Ii]?[Bb]\z/
    MEGABYTES = { m: 1, g: 1024, t: 1024 * 1024 }.freeze
    private_constant(:FORM, :MEGABYTES)

    def self.megabytes(text)
      match = (text.is_a?(String) && text.valid_encoding?) ? FORM.match(text) : nil
      # Rational keeps 0.1 as exactly 1/10, so a decimal that no binary float holds still rounds up exactly.
      match && (Rational(match[:number]) * MEGABYTES[match[:unit].downcase.to_sym]).ceil
    end
  end
  private_constant(:SizeText)
end
