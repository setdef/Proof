# frozen_string_literal: true

module Proof
  class Error < StandardError
  end

  class InvalidOSError < Error
  end

  class InvalidLabelError < Error
  end

  class InvalidLabelSetError < Error
  end

  class InvalidResourcesError < Error
  end

  class InvalidRunIdError < Error
  end
end
