# frozen_string_literal: true

module Usage
  class Spec < Data.define(:bin, :about, :about_long, :after_help_long, :examples, :commands, :env_prefix, :env_allowed)
    def self.read(text)
      SpecFormat.read(text)
    end

    def exit_codes
      commands.root.exit_codes
    end

    # @dynamic bin, about, about_long, after_help_long, examples, commands, env_prefix, env_allowed, initialize
  end
end
