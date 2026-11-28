# frozen_string_literal: true

module Usage
  class EmptyValue < Data.define(:text)
    def refused_by?(_rules)
      false
    end

    # @dynamic text, initialize
  end
end
