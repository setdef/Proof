# frozen_string_literal: true

module Proof
  module CommandLine
    class LoginCommand < Data.define(:server, :code_file)
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic server, code_file, initialize
    end
  end
end
