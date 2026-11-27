# frozen_string_literal: true

module Usage
  module ExampleFormat
    KEYS = %w[code header help lang=""].freeze
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, parent.child("an example"), KEYS)
      Example.new(code: reader.text(:code).to_s, header: reader.text(:header), help: reader.text(:help))
    end
  end
end
