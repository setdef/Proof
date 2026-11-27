# frozen_string_literal: true

module Proof
  module LengthPrefixed
    def self.join(*fields)
      # Eight bytes of length leave no field too long to count, where four would wrap at 4 GiB.
      fields.each_with_object(+"".b) { |field, joined| joined << [field.bytesize].pack("Q>") << field.b }
    end
  end
end
