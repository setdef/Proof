# frozen_string_literal: true

# What the gem's parser gave for a command line, in the terms of usage's corpus: the command's path, and the value of
# each flag and argument that the line set, by the name the spec gives it.
class CorpusReading
  # The spec the line was read by, and the `Usage::Parsed` it gave.
  def initialize(spec, parsed)
    @spec = spec
    @parsed = parsed
  end

  # The reading as the corpus writes `ok`.
  def to_h
    { cmd: command.path, flags:, args: }
  end

  # The command the words reached.
  private def command
    @parsed.command
  end

  # The value of each flag that was given, whether the command or one above it has the flag.
  private def flags
    in_reach.select { |flag| @parsed.given?(flag.name) }
      .to_h { |flag| [flag.name.to_sym, flag_value(flag)] }
  end

  # Every flag that a word could have set: those of each command on the path, and the global flags of the path.
  private def in_reach
    commands = (0..(command.path.size)).map { |size| @spec.commands.find(command.path.first(size)) }
    (commands.flat_map(&:own_flags) + @spec.commands.global_flags(command.path)).uniq
  end

  # `true` for a flag that takes no value, the values of one that repeats, and the last value otherwise.
  private def flag_value(flag)
    return true unless flag.takes_value?

    values = @parsed.values(flag.name)
    flag.repeatable? ? values : values.last
  end

  # The words each argument took.
  private def args
    command.args.reject { |arg| @parsed.words(arg.name).empty? }
      .to_h { |arg| [arg.name.to_sym, arg_value(arg)] }
  end

  # Every word for an argument that repeats, and its only word otherwise.
  private def arg_value(arg)
    words = @parsed.words(arg.name)
    arg.repeatable? ? words : words.first
  end
end
