# frozen_string_literal: true

require_relative("named_format")

module Usage
  module FlagFormat
    KEYS = %w[name usage help help_long help_first_line short long var global arg requires hide=false].freeze
    VALUE_KEYS = %w[name usage choices required=true double_dash="Optional" hide=false].freeze
    CHOICE_KEYS = %w[choices strict=true strict=false].freeze
    private_constant(:KEYS, :VALUE_KEYS, :CHOICE_KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, parent.child("flag #{object[:name]}"), KEYS)
      Flag.new(
        **NamedFormat.name_and_help(reader),
        short: reader.texts(:short),
        long: reader.texts(:long),
        **valued(reader),
        requires: reader.texts(:requires),
        global: reader.boolean(:global)
      )
    end

    def self.valued(reader)
      value = reader.nested(:arg, VALUE_KEYS)
      var = reader.boolean(:var)
      # usage counts a yes-or-no flag that repeats, and the parser has no count to give.
      reader.unsupported("repeats with no value") if var && !value

      choices = value&.nested(:choices, CHOICE_KEYS)
      {
        value: value&.text(:name),
        choices: Choices.new(values: choices&.texts(:choices) || [], strict: !choices&.false?(:strict)),
        repeatable: var,
      }
    end
    private_class_method(:valued)
  end
end
