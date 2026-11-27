# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Place < Data.define(:name)
    # steep:ignore:end
    PROGRAM = new(name: "the program")
    public_constant(:PROGRAM)

    def self.command(path)
      path.empty? ? PROGRAM : new(name: "command #{path.join(' ')}")
    end

    def child(part)
      Place.new(name: "#{part} of #{name}")
    end

    def within(key)
      Place.new(name: "#{name}, in #{key}")
    end

    def unsupported(what)
      raise(SpecError, "#{name} #{what}, which usage-rb doesn't support")
    end

    def mistyped(key, form)
      raise(SpecError, "#{name} has #{key} that isn't #{form}")
    end
  end
end
