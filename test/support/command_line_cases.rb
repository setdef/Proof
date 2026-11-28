# frozen_string_literal: true

require "shellwords"
require_relative("command_line_bundles")
require_relative("command_line_contract")

module CommandLineContract
  # The command lines to compare, made from the spec: every flag in each form, every command's arguments, and more.
  class Cases
    # The rules of `proof run` for its words: `--`, `:::`, and what goes to the task.
    RUN_WORDS = [
      %w[test -- a b],
      %w[test a b],
      %w[test -- -x],
      %w[test -- --os linux],
      %w[--os linux test],
      %w[test --os linux a],
      %w[lint ::: test],
      %w[lint -- --fix ::: test -- --seed 1],
      %w[lint ::: test -- x],
      %w[lint -- a -- b],
      %w[-- test],
      %w[test --],
      %w[test a ::: x b -- c],
      %w[lint ::: test ::: build],
      %w[--script f -- a],
      %w[--script f],
      %w[--script -],
      %w[--script f test],
      %w[--script f -q],
      %w[test -q -- a -q],
      %w[a ::: b -- c -- d],
      %w[lint -- a ::: -- b],
      %w[lint -- a -- ::: test -- b -- c],
      %w[lint ::: test -- -- x],
      %w[-- lint ::: test -- x],
      %w[lint ::: test --os linux],
    ].freeze
    private_constant(:RUN_WORDS)

    def initialize(spec)
      @spec = spec
    end

    # Every command line, as the words after `proof`.
    def all
      (commands.flat_map { |command| for_command(command) } + [["--version"]] + examples +
        RUN_WORDS.map { |words| ["run", *words] }).uniq
    end

    # The leaf and branch commands, except `proof` itself, whose bare form prints help where usage accepts it.
    private def commands
      walk = -> (command) { [command, *command.subcommands.flat_map(&walk)] }
      walk.call(@spec.commands.root).drop(1)
    end

    private def for_command(command)
      return leaf_cases(command) + abbreviated_command(command) if command.subcommands.empty?

      [command.path, [*command.path, "nope"], [*command.path, "-h"], [*command.path, "--help"]] +
        abbreviated_command(command)
    end

    # proof.usage.kdl: a command is typed in full, so the front of its name names no command.
    private def abbreviated_command(command)
      *parents, name = command.path
      [[*parents, front(name), *words(command)], [*parents, name[0, 1].to_s, *words(command)]]
    end

    # All of a word but its last character, which names nothing the spec defines.
    private def front(word)
      word[0...-1].to_s
    end

    private def leaf_cases(command)
      base = [*command.path, *words(command)]
      [base, [*base, "extra"], command.path, [*base, "-h"], [*base, "--"], [*base, "--", "extra"], [*base, "--nope"]] +
        command.own_flags.flat_map { |flag| flag_cases(command, base, flag) } + globals(command, base)
    end

    # The words that satisfy the command's required arguments, or its task for `proof run`.
    private def words(command)
      return ["test"] if command.path == ["run"]

      Array.new(command.args.count(&:required?), "x")
    end

    private def flag_cases(command, base, flag)
      value = flag.choices.values.first || "v"
      cases = flag.switches.flat_map { |switch| switch_cases(command, base, flag, switch, value) }
      cases += flag.requires.map { |required| [*base, flag.switches.last, *(value if flag.takes_value?), required] }
      cases + abbreviations(base, flag, value)
    end

    # proof.usage.kdl: a flag is typed in full, so the front of its name is no flag, and neither is the front of one
    # of its choices a choice.
    private def abbreviations(base, flag, value)
      given = flag.takes_value? ? [value] : []
      fronts = flag.long.flat_map { |word| ["--#{front(word)}", "--#{word[0, 1]}"] }
      fronts.flat_map { |switch| [[*base, switch], [*base, switch, *given]] } + choices_cut(base, flag)
    end

    private def choices_cut(base, flag)
      flag.choices.values.map { |choice| [*base, flag.switches.last, front(choice)] }
    end

    private def switch_cases(command, base, flag, switch, value)
      given = [switch, *(value if flag.takes_value?)]
      before = [*command.path, *given, *words(command)]
      ahead = [*given, *base]
      return [[*base, switch], before, ahead, [*base, switch, switch]] unless flag.takes_value?

      other = flag.choices.values[1] || "w"
      [[*base, switch, value], before, ahead, [*base, switch, value, switch, other], [*base, "#{switch}=#{value}"]] +
        [[*base, switch], [*base, switch, "-x"], [*base, switch, "bogus"]] + Bundles.new(base, switch, value).cases
    end

    private def globals(command, base)
      switches = @spec.commands.at([]).global_flags.flat_map(&:switches)
      switches.flat_map { |switch| [[switch, *base], [*base, switch], [*command.path, switch, *words(command)]] } +
        [[*base, "-qd"], [*base, "-q", "-d"], ["-qd", *base], ["--nope", *base], ["-x", *base], ["--quie", *base]]
    end

    private def examples
      (@spec.examples + commands.flat_map(&:examples)).map { |example| Shellwords.split(example.code).drop(1) }
    end
  end
end
