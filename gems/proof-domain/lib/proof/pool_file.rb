# frozen_string_literal: true

require_relative("host_entry")
require_relative("host_settings")
require_relative("limits")
require_relative("member_check")
require_relative("pool_names")
require_relative("port")
require_relative("repository_entry")
require_relative("retention")

module Proof
  class PoolFile < Data.define(:port, :retention, :limits, :defaults, :hosts, :repositories)
    # @type var rules: Hash[Symbol, [String, MemberCheck::rule]]
    rules = {
      port: ["a pool file's port is a Proof::Port, not %p", Port.method(:===)],
      retention: ["a pool file's retention is a Proof::Retention, not %p", Retention.method(:===)],
      limits: ["a pool file's limits are a Proof::Limits, not %p", Limits.method(:===)],
      defaults: ["a pool file's defaults are host settings, not %p", HostSettings.method(:===)],
      hosts: [
        "a pool file's hosts are a list of host entries, not %p",
        -> (value) { value.is_a?(Array) && value.all?(HostEntry) },
      ],
      repositories: [
        "a pool file's repositories are a list of repository entries, not %p",
        -> (value) { value.is_a?(Array) && value.all?(RepositoryEntry) },
      ],
    }
    RULES = rules.freeze
    # @type var defaults: Hash[Symbol, Object]
    defaults = {
      port: Port.new(number: 7443),
      retention: Retention.new,
      limits: Limits.new,
      defaults: HostSettings.new,
      hosts: [],
      repositories: [],
    }
    DEFAULTS = defaults.freeze
    private_constant(:RULES, :DEFAULTS)

    def initialize(**given)
      # The keywords arrive as one hash, since six keywords make a parameter list longer than RuboCop accepts.
      settings = checked(given)
      # checked has found a list of host entries and a list of repository entries, which Steep can't know.
      hosts = settings.fetch(:hosts) #: Array[HostEntry]
      repositories = settings.fetch(:repositories) #: Array[RepositoryEntry]
      PoolNames.refuse_repeats(hosts, repositories)
      super(**settings, hosts: hosts.dup.freeze, repositories: repositories.dup.freeze)
      # A host with no budget in its entry or in the defaults is refused when it is resolved.
      resolved_hosts
    end

    def resolved_hosts
      hosts.map { |host| host.resolved(defaults) }
    end

    private def checked(given)
      unknown = given.keys - members
      raise(ArgumentError, "unknown keyword: #{unknown.first.inspect}") unless unknown.empty?

      DEFAULTS.merge(given).tap do |settings|
        problem = MemberCheck.problem(RULES, settings)
        raise(InvalidPoolFileError, problem) if problem
      end
    end

    # @dynamic port, retention, limits, defaults, hosts, repositories
  end
end
