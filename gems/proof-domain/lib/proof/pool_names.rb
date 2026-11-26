# frozen_string_literal: true

module Proof
  module PoolNames
    REPEATED = "two %<plural>s are named %<name>p. Each %<singular>s has one entry, so merge them into one"
    SHARED = "the runner %<runner>p is listed on the hosts %<first>p and %<second>p. " \
      "A runner is one operating system on one host, so list it on one"
    private_constant(:REPEATED, :SHARED)

    def self.refuse_repeats(hosts, repositories)
      refuse_repeated(hosts, "hosts", "host")
      refuse_shared_runners(hosts)
      refuse_repeated(repositories, "repositories", "repository")
    end

    def self.refuse_repeated(entries, plural, singular)
      name, = entries.map(&:name).tally.find { |_, times| times > 1 }
      return unless name

      raise(InvalidPoolFileError, format(REPEATED, plural:, name:, singular:))
    end
    private_class_method(:refuse_repeated)

    def self.refuse_shared_runners(hosts)
      runner, = hosts.flat_map(&:runners).tally.find { |_, times| times > 1 }
      refuse_shared(runner, hosts) if runner
    end
    private_class_method(:refuse_shared_runners)

    def self.refuse_shared(runner, hosts)
      first, second = hosts.filter_map { |host| host.name if host.runners.include?(runner) }
      raise(InvalidPoolFileError, format(SHARED, runner:, first:, second:))
    end
    private_class_method(:refuse_shared)
  end
  private_constant(:PoolNames)
end
