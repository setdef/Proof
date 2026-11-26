# frozen_string_literal: true

require_relative("file_error")

module Proof
  class PoolFileError < FileError
    QUOTED_AS = "budget \"400GB\" or limits output=\"1GB\""
    public_constant(:QUOTED_AS)
  end
end
