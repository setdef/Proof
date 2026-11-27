# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Spec < Data.define(
    :bin,
    :about,
    :about_long,
    :after_help,
    :examples,
    :exit_codes,
    :commands,
    :env_prefix,
    :env_allowed
  )
    # steep:ignore:end
    def self.read(text)
      SpecFormat.read(text)
    end
  end
end
