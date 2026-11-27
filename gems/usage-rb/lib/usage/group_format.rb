# frozen_string_literal: true

module Usage
  module GroupFormat
    KEYS = %w[name members required multiple].freeze
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, "group #{object[:name]} of #{parent}", KEYS)
      Group.new(
        name: reader.text(:name).to_s,
        names: reader.texts(:members),
        required: reader.boolean(:required),
        multiple: reader.boolean(:multiple)
      )
    end
  end
end
