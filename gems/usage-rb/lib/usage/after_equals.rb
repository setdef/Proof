# frozen_string_literal: true

module Usage
  class AfterEquals < Data.define(:text)
    def refused_by?(rules)
      rules.refuses_equals?(text)
    end

    # @dynamic text, initialize
  end
end
