# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Arg < Data.define(:name, :help, :help_long, :required, :repeatable)
    # steep:ignore:end
    def required?
      required
    end

    def repeatable?
      repeatable
    end

    def to_s
      label = repeatable ? "#{name}..." : name
      required ? "<#{label}>" : "[#{label}]"
    end
  end
end
