# frozen_string_literal: true

module Proof
  class PoolFileEntries
    SAME_NAME = lambda do |one, other|
      # The rule of the domain's PoolNames and of Proof::Label, String#casecmp?. A name that isn't text, which the
      # domain refuses later, compares as KDL read it. A lambda, so that a name can be curried into the test of a list.
      (one.is_a?(String) && other.is_a?(String)) ? one.casecmp?(other) : one == other
    end
    private_constant(:SAME_NAME)

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
      first = entries(kind).take(index).find { |other| SAME_NAME.call(other.arguments.first, entry.arguments.first) }
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
      first = earlier.find { |other| other.arguments_named("runner").any?(&SAME_NAME.curry[runner]) }
      @refusal.shared_runner(child, runner, first) if first
    end
  end
end
