# frozen_string_literal: true

require_relative("keys")
require_relative("named_format")

module Usage
  module ArgFormat
    KEYS = Keys.new(
      read: %i[name usage help help_long help_first_line required var],
      defaults: { double_dash: "Optional", hide: false }
    )
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, parent.child("argument #{object[:name]}"), KEYS)
      Arg.new(
        **NamedFormat.name_and_help(reader),
        required: reader.boolean(:required),
        repeatable: reader.boolean(:var)
      )
    end
  end
end
