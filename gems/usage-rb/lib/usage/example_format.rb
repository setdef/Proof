# frozen_string_literal: true

require_relative("keys")
module Usage
  module ExampleFormat
    KEYS = Keys.new(read: %i[code header help], defaults: { lang: "" })
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, parent.child("an example"), KEYS)
      Example.new(code: reader.text(:code).to_s, header: reader.text(:header), help: reader.text(:help))
    end
  end
end
