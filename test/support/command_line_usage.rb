# frozen_string_literal: true

require_relative("command_line_contract")

module CommandLineContract
  # Asks `usage explain` how a command line binds to the CLI spec, and reads the answer as an Outcome.
  class Usage
    SPEC = File.expand_path("../../proof.usage.kdl", __dir__)
    BAD_ROLES = %w[unknown_flag unread refused].freeze
    private_constant(:SPEC, :BAD_ROLES)

    def initialize(spec)
      @repeating = spec.root.subcommands.flat_map(&:flags).select(&:repeatable?).to_set(&:name)
    end

    # The outcome of +argv+, the words after `proof`.
    def outcome(argv)
      out, status = Open3.capture2("usage", "explain", "--format", "json", "-f", SPEC, "--", "proof", *argv)
      raise(IOError, "usage explain failed on #{argv.inspect}") unless status.success?

      read(JSON.parse(out))
    end

    private def read(report)
      roles = report["tokens"].flat_map { |token| token["roles"] }
      return REFUSED if refused?(report, roles)
      return HELP if roles.any? { |role| role["kind"] == "builtin" }

      Outcome.new(kind: :accepted, command: report["command"].drop(1), flags: flags(roles), args: args(roles))
    end

    private def refused?(report, roles)
      report["refused"] || !report["errors"].empty? || roles.any? { |role| BAD_ROLES.include?(role["kind"]) }
    end

    private def flags(roles)
      found = Hash.new { |hash, name| hash[name] = [] }
      roles.each { |role| note(found, role) }
      found.to_h { |name, values| [name, @repeating.include?(name) ? values : values.last(1)] }
    end

    private def note(found, role)
      case role["kind"]
      when "flag" then found[role["name"]] << true
      when "value" then found[role["name"]][-1] = role["values"].first
      end
    end

    private def args(roles)
      found = Hash.new { |hash, name| hash[name] = [] }
      separated = false
      roles.each do |role|
        separated = true if role["kind"] == "separator"
        role["values"].each { |word| found[role["name"]] << [word, separated] } if role["kind"] == "arg"
      end
      found.transform_values { |entries| words(entries) }
    end

    # proof.usage.kdl: after `:::` comes the task's name, and its words follow a `--`. When `:::` follows the first
    # `--`, usage binds the `--` after the name as a word, where the parser takes it as the separator, so it isn't
    # one of the words to compare. Every other `--` is a word for both.
    private def words(entries)
      entries.each_with_index.filter_map do |(word, _), index|
        word unless word == "--" && index >= 2 && entries[index - 2] == [":::", true]
      end
    end
  end
end
