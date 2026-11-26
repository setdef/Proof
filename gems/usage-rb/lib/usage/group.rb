# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Group < Data.define(:name, :names, :required, :multiple)
    # steep:ignore:end
    KEYS = %w[name members required multiple].freeze
    private_constant(:KEYS)

    def self.read(object, command)
      reader = Reader.new(object, "group #{object[:name]} of #{command}", KEYS)
      new(
        name: reader.text(:name).to_s,
        names: reader.texts(:members),
        required: reader.boolean(:required),
        multiple: reader.boolean(:multiple)
      )
    end

    def required?
      required
    end

    def multiple?
      multiple
    end
  end
end
