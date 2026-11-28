# frozen_string_literal: true

module Usage
  class Group < Data.define(:name, :names, :required, :multiple)
    def required?
      required
    end

    def multiple?
      multiple
    end

    # @dynamic name, names, required, multiple, initialize
  end
end
