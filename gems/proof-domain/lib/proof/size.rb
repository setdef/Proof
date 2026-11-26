# frozen_string_literal: true

require_relative("member_check")
require_relative("size_text")

module Proof
  # steep:ignore:start
  class Size < Data.define(:megabytes)
    # steep:ignore:end
    MESSAGE = "%s is a size: a number, whole or decimal, an optional space, and MB, GB, TB, MiB, GiB, or TiB " \
      "in any case, such as \"512MB\", \"8 GB\", \"1.5gib\", or \"0.5TB\", not %p"
    private_constant(:MESSAGE)

    def self.read(text, name:)
      megabytes = SizeText.megabytes(text)
      raise(InvalidSizeError, format(MESSAGE, name, text)) unless megabytes

      new(megabytes:)
    end

    def initialize(megabytes:)
      raise(InvalidSizeError, format("a size is a whole number of megabytes from 0, not %p", megabytes)) unless
        MemberCheck.whole?(megabytes, 0)

      super
    end
  end
end
