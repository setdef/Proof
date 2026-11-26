# frozen_string_literal: true

module Proof
  module PathText
    def self.relative?(text)
      # The project file page refuses a path that contains two dots, so a name such as v1..2.txt goes too. Text with
      # a byte that isn't valid, or in an encoding such as UTF-16, can't be searched for them.
      text.is_a?(String) && text.valid_encoding? && text.encoding.ascii_compatible? &&
        !text.empty? && !text.start_with?("/") && !text.include?("..")
    end
  end
  private_constant(:PathText)
end
