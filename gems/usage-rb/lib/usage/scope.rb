# frozen_string_literal: true

module Usage
  class Scope
    def initialize(flags)
      @flags = flags.flat_map { |flag| flag.switches.product([flag]) }
        .to_h
      @valued = flags.select(&:takes_value?).flat_map(&:switches)
    end

    def flag(switch)
      # The help that usage gives every command answers to each switch of it that no flag of the spec has.
      @flags.fetch(switch) { Flag::HELP if Flag::HELP.switches.include?(switch) }
    end

    def switches
      @flags.keys | Flag::HELP.switches
    end

    def letters?(word)
      # usage checks the letters before it reads any, up to one that takes a value: the letters after it are no flags.
      word.delete_prefix("-").each_char.all? do |letter|
        switch = "-#{letter}"
        break true if @valued.include?(switch)

        flag(switch)
      end
    end
  end
end
