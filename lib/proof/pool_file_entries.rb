# frozen_string_literal: true

module Proof
  class PoolFileEntries
    def initialize(by_name:, refusal:)
      @by_name = by_name
      @refusal = refusal
    end

    def check
      refuse_repeats(:host)
      refuse_shared_runners
      refuse_repeats(:repository)
    end

    private def entries(kind)
      @by_name[kind].to_a
    end

    private def refuse_repeats(kind)
      entries(kind).each_with_index { |entry, index| refuse_repeat(entry, kind, index) }
    end

    private def refuse_repeat(entry, kind, index)
      first = entries(kind).take(index).find { |other| other.arguments.first == entry.arguments.first }
      @refusal.repeated_entry(entry, first) if first
    end

    private def refuse_shared_runners
      entries(:host).each { |host| refuse_shared_in(host) }
    end

    private def refuse_shared_in(host)
      host.pairs_named("runner").each { |runner, child| refuse_listed(child, runner, host) }
    end

    private def refuse_listed(child, runner, host)
      earlier = entries(:host).take_while { |other| !other.equal?(host) }
      first = earlier.find { |other| other.arguments_named("runner").include?(runner) }
      @refusal.shared_runner(child, runner, first) if first
    end
  end
end
