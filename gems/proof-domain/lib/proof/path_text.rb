# frozen_string_literal: true

module Proof
  module PathText
    FORM = %r{\A(?!/)(?!(?:.*/)?\.\.(?:/|\z)).+\z}m
    private_constant(:FORM)

    def self.relative?(text)
      # FORM wants text that isn't empty, doesn't start with a slash, and has no folder named .. at its start,
      # after a slash, or at its end. Text with a byte that isn't valid, or in an encoding such as UTF-16, can't be
      # matched against it.
      text.is_a?(String) && text.valid_encoding? && text.encoding.ascii_compatible? && FORM.match?(text)
    end
  end
  private_constant(:PathText)
end
