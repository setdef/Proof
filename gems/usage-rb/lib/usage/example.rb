# frozen_string_literal: true

module Usage
  class Example < Data.define(:code, :header, :help)
    # @dynamic code, header, help, initialize
  end
end
