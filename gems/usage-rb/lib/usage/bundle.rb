# frozen_string_literal: true

module Usage
  class Bundle
    def initialize(switches, stray)
      @switches = switches
      @stray = stray
    end

    def read(line)
      awaiting = @switches.each_with_object(Awaiting.new(line)) { |switch, waiting| waiting.reach(switch) }
      # usage reaches a letter that names no flag only if help hasn't ended the reading.
      @stray&.call unless line.help?
      awaiting.given
    end
  end
end
