# frozen_string_literal: true

require_relative("command_line_contract")

module CommandLineContract
  # Parses a command line with `proof`'s parser, and reads the result as an Outcome.
  class Parsed
    def initialize(spec)
      @spec = spec
    end

    # The outcome of +argv+, the words after `proof`.
    def outcome(argv)
      result = Proof::CommandLine.parse(argv)
      return HELP if result.is_a?(Proof::CommandLine::HelpAsked)
      return version if result.is_a?(Proof::CommandLine::VersionAsked)

      path = words_of(result.command)
      Outcome.new(kind: :accepted, command: path, flags: flags(path, result), args: args(path, result.command))
    rescue Proof::CommandLine::Mistake
      REFUSED
    end

    # A request for the version is `--version` given to `proof` itself, where no command runs.
    private def version
      Outcome.new(kind: :accepted, command: [], flags: { version: [true] }.transform_keys(&:to_s), args: {})
    end

    # `RunnerSetupCommand` is the command `runner setup`.
    private def words_of(command)
      command.class.name.split("::").last.delete_suffix("Command").scan(/[A-Z][a-z]+/).map(&:downcase)
    end

    private def flags(path, result)
      lineage = @spec.commands.at(path)
      own = values(lineage.command.own_flags, result.command)
      without_empty(own.merge(values(lineage.global_flags, result.global)))
    end

    # Each of +flags+ by its name, with what +parsed+ holds for it.
    private def values(flags, parsed)
      flags.to_h { |flag| [flag.name, read(parsed, flag.name)] }
    end

    private def args(path, command)
      return run_args(command) if path == ["run"]

      given = @spec.commands.find(path).args.to_h do |arg|
        [arg.name, read(command, arg.repeatable? ? "#{arg.name}s" : arg.name)]
      end
      without_empty(given)
    end

    # `proof run` holds its task and the words after it as tasks, where the spec has a task and its args, and a
    # script's words as their own, which usage binds to the task and args. A `--` that is a word of a task stays in
    # the words, so a `--` taken as a separator, or the reverse, is a disagreement.
    private def run_args(command)
      first, *others = command.script_words.empty? ? command.tasks : script_tasks(command)
      return {} unless first

      later = others.flat_map { |task| [":::", task.name, *task.words] }
      without_empty([["task", [first.name]], ["args", first.words + later]].to_h)
    end

    private def script_tasks(command)
      name, *words = command.script_words
      [Proof::CommandLine::TaskWords.new(name:, words:)]
    end

    private def read(holder, name)
      value = holder.public_send(name.tr("-", "_"))
      case value
      when true, String then [value]
      when Array then value
      else []
      end
    end

    private def without_empty(found)
      found.reject { |_, values| values.empty? }
    end
  end
end
