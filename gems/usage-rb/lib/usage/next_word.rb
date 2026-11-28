# frozen_string_literal: true

module Usage
  class NextWord < Data.define(:text)
    def refused_by?(rules)
      rules.refuses_next?(text)
    end

    # @dynamic text, initialize
  end
end
