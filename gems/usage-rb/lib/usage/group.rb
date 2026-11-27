# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Group < Data.define(:name, :names, :required, :multiple)
    # steep:ignore:end
    def required?
      required
    end

    def multiple?
      multiple
    end
  end
end
