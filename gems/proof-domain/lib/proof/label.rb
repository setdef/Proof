# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class Label < Data.define(:name)
    # steep:ignore:end
    FORM = /\A[A-Za-z0-9](?:[A-Za-z0-9._-]{0,61}[A-Za-z0-9])?\z/
    MESSAGE = "a label is 1 to 63 ASCII letters, digits, hyphens, underscores, or dots, " \
      "beginning and ending with a letter or a digit, with no space, such as " \
      "gpu, kvm, or cuda-12.4, not %p"
    private_constant(:FORM, :MESSAGE)

    def initialize(name:)
      raise(InvalidLabelError, format(MESSAGE, name)) unless
        name.is_a?(String) && name.ascii_only? && FORM.match?(name)

      super(name: -name)
    end

    def ==(other)
      case other
      when Label then name.casecmp?(other.name)
      else false
      end
    end
    alias eql? ==

    def hash
      [Label, name.downcase].hash
    end

    def to_s
      name
    end
  end
end
