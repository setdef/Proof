# frozen_string_literal: true

module Usage
  module ArgFormat
    KEYS = %w[name usage help help_long help_first_line required var double_dash="Optional" hide=false].freeze
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, "argument #{object[:name]} of #{parent}", KEYS)
      Arg.new(required: reader.boolean(:required), repeatable: reader.boolean(:var), **reader.name_and_help)
    end
  end
end
