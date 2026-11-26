# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Arg < Data.define(:name, :help, :help_long, :required, :var)
    # steep:ignore:end
    KEYS = %w[name usage help help_long help_first_line required var double_dash="Optional" hide=false].freeze
    private_constant(:KEYS)

    def self.read(object, command)
      reader = Reader.new(object, "argument #{object[:name]} of #{command}", KEYS)
      new(name: reader.name, required: reader.boolean(:required), var: reader.boolean(:var), **reader.descriptions)
    end

    def required?
      required
    end

    def repeatable?
      var
    end

    def to_s
      label = var ? "#{name}..." : name
      required ? "<#{label}>" : "[#{label}]"
    end
  end
end
