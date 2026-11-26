# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class KdlSyntaxReason < Data.define(:error)
    # steep:ignore:end
    QUOTE_HINT = ". If a value starts with a digit and continues with letters, put it in quotes, as in memory=\"8GB\""
    private_constant(:QUOTE_HINT)

    def to_s
      reason = "this is not valid KDL 2: #{said} at column #{error.column}"
      said.start_with?("unexpected IDENT") ? reason + QUOTE_HINT : reason
    end

    private def said
      # The gem ends its message with the position, which the reason gives in its own words.
      error.message.delete_suffix(" (#{error.line}:#{error.column})")
    end
  end
end
