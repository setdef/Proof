# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Flag < Data.define(:name, :short, :long, :value, :help, :help_long, :choices, :strict, :requires, :var, :global)
    # steep:ignore:end
    KEYS = %w[name usage help help_long help_first_line short long var global arg requires hide=false].freeze
    VALUE_KEYS = %w[name usage choices required=true double_dash="Optional" hide=false].freeze
    CHOICE_KEYS = %w[choices strict=true strict=false].freeze
    private_constant(:KEYS, :VALUE_KEYS, :CHOICE_KEYS)

    def self.read(object, command)
      where = "flag #{object[:name]} of #{command}"
      reader = Reader.new(object, where, KEYS)
      new(
        **reader.descriptions,
        short: reader.texts(:short),
        long: reader.texts(:long),
        **valued(reader, where),
        requires: reader.texts(:requires),
        global: reader.boolean(:global)
      )
    end

    def repeatable?
      var
    end

    def global?
      global
    end

    def strict?
      strict
    end

    def takes_value?
      value.is_a?(String)
    end

    def accepts?(word)
      # A flag with no choices is strict, and has nothing to check its value against.
      choices.empty? || !strict || choices.include?(word)
    end

    def switches
      short.map { |letter| "-#{letter}" } + long.map { |word| "--#{word}" }
    end

    def self.valued(reader, where)
      value = reader.nested(:arg, VALUE_KEYS)
      var = reader.boolean(:var)
      # usage counts a yes-or-no flag that repeats, and the parser has no count to give.
      raise(SpecError, "#{where} repeats with no value, which usage-rb doesn't support") if var && !value

      choices = value&.nested(:choices, CHOICE_KEYS)
      {
        value: value&.text(:name),
        choices: choices&.texts(:choices) || [],
        strict: !choices&.false?(:strict),
        var:,
      }
    end
    private_class_method(:valued)
  end
end
