# frozen_string_literal: true

module Usage
  class Given < Data.define(:scope, :values, :args)
    def gives?(member)
      # A group and a requirement name a flag by a switch, and an argument by its name.
      member.start_with?("-") ? values.given?(scope.flag(member)) : !args.fetch(member, []).empty?
    end

    def gives_any?(members)
      members.any? { |member| gives?(member) }
    end

    def unmet(flag)
      flag.requires.find { |switch| !gives?(switch) } if values.given?(flag)
    end

    # @dynamic scope, values, args, initialize
  end
end
