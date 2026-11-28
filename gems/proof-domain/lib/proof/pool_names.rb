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
      names = entries.map(&:name)
      repeat = Name.first_repeat(names)
      return unless repeat

      # The pair is named by its earlier name, as that entry wrote it.
      raise(InvalidPoolFileError, format(REPEATED, plural:, name: names[repeat.first], singular:))
    end
    private_class_method(:refuse_repeated)

    def self.refuse_shared_runners(hosts)
      runners = hosts.flat_map(&:runners)
      repeat = Name.first_repeat(runners)
      refuse_shared(runners, hosts, repeat) if repeat
    end
    private_class_method(:refuse_shared_runners)

    def self.refuse_shared(runners, hosts, repeat)
      earlier, later = repeat
      first, second = hosts_of(hosts).values_at(earlier, later)
      raise(InvalidPoolFileError, format(SHARED, runner: runners[earlier], first:, second:))
    end
    private_class_method(:refuse_shared)

    def self.hosts_of(hosts)
      # The host of each runner, in the order of the runners that refuse_shared_runners lists.
      hosts.flat_map { |host| host.runners.map { host.name } }
    end
    private_class_method(:hosts_of)
  end
  private_constant(:PoolNames)
end
