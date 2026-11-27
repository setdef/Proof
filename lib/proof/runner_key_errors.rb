# frozen_string_literal: true

module Proof
  class RunnerKeyError < Error
  end

  class InvalidEncryptedTokenError < Error
  end

  class TokenDecryptionError < Error
  end
end
