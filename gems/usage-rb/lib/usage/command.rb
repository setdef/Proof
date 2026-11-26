# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Command < Data.define(
    :name,
    :path,
    :help,
    :help_long,
    :args,
    :flags,
    :subcommands,
    :groups,
    :examples,
    :subcommand_required
  )
    # steep:ignore:end
    KEYS = %w[
      name
      full_cmd
      usage
      help
      help_long
      args
      flags
      subcommands
      groups
      examples
      subcommand_required
      effect
      unknown_flags="error"
      args_override_self=true
      hide=false
      aliases=[]
      hidden_aliases=[]
      mounts=[]
      headings=[]
    ].freeze
    private_constant(:KEYS)

    def self.read(object)
      where = place(object[:full_cmd])
      command = new(**parts(Reader.new(object, where, KEYS)))
      # A word after a command with both would be an argument or a subcommand's name, and usage decides by rules the
      # parser doesn't follow.
      raise(SpecError, "#{where} has both arguments and subcommands, which usage-rb doesn't support") unless
        command.args.empty? || command.subcommands.empty?

      command
    end

    def subcommand_required?
      subcommand_required
    end

    def subcommand(word)
      subcommands.find { |child| child.name == word }
    end

    def subcommand_names
      subcommands.map(&:name)
    end

    def own_flags
      flags.reject(&:global?)
    end

    def global_flags
      flags.select(&:global?)
    end

    def self.place(words)
      (words.is_a?(Array) && !words.empty?) ? "command #{words.join(' ')}" : "the program"
    end
    private_class_method(:place)

    def self.parts(reader)
      {
        **reader.descriptions,
        path: reader.texts(:full_cmd),
        args: reader.parts(:args, Arg),
        flags: reader.parts(:flags, Flag),
        groups: reader.parts(:groups, Group),
        examples: reader.parts(:examples, Example),
        subcommands: reader.members(:subcommands).map { |child| read(child) },
        subcommand_required: reader.boolean(:subcommand_required),
      }
    end
    private_class_method(:parts)
  end
end
