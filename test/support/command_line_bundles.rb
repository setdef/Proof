# frozen_string_literal: true

require_relative("command_line_contract")

module CommandLineContract
  # The command lines that write letters after a short flag that takes a value.
  #
  # With `unknown_flags "error"`, usage reads each letter after a short flag that takes a value as a flag, and refuses
  # a letter that names none, so `-Cdir` is refused at `i`, `-C/tmp/x` at `/`, and `-Cd path` is `-C -d path`. It reads
  # the letters one by one, so `-hCx` asks for help before it reaches `x`, and `-Ch path` leaves `-C` no value before
  # it reaches `path`. A flag written twice in a word keeps the empty value.
  class Bundles
    # Takes the words before the flag, the flag's switch, and a value it takes.
    def initialize(base, switch, value)
      @base = base
      @switch = switch
      @value = value
      @letter = switch.delete_prefix("-")
    end

    # The command lines, none when the switch is a long flag's.
    def cases
      return [] unless @switch.match?(/\A-[^-]\z/)

      refused + valued_then_flags + help_first + [[*@base, "-d#{@letter}#{@value}"]]
    end

    private def refused
      rests = [@value, "=#{@value}", "==#{@value}", "=", "/tmp/x", "d#{@value}", "q#{@value}", "h", "dh", "-", "d-"]
      rests.map { |rest| [*@base, "#{@switch}#{rest}"] }
    end

    private def valued_then_flags
      ["d", "dd", "dq", "qd", "h", "dh", @letter, "d#{@letter}"].map { |rest| [*@base, "#{@switch}#{rest}", @value] }
    end

    private def help_first
      %w[x - d-].map { |rest| [*@base, "-h#{@letter}#{rest}"] }
    end
  end
end
