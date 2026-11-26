# frozen_string_literal: true

module Usage
  module CommandReader
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
      unknown_flags=null
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
      reader = Reader.new(object, where, KEYS)
      command = Command.new(**described(reader), **reader.descriptions, **words(reader, where), **parts(reader, where))
      # A word after a command with both would be an argument or a subcommand's name, and usage decides by rules the
      # parser doesn't follow.
      raise(SpecError, "#{where} has both arguments and subcommands, which usage-rb doesn't support") unless
        command.args.empty? || command.subcommands.empty?

      command
    end

    def self.place(words)
      (words.is_a?(Array) && !words.empty?) ? "command #{words.join(' ')}" : "the program"
    end
    private_class_method(:place)

    def self.described(reader)
      { name: reader.name, path: reader.texts(:full_cmd) }
    end
    private_class_method(:described)

    def self.words(reader, where)
      {
        args: reader.objects(:args).map { |arg| Arg.read(arg, where) },
        subcommands: reader.members(:subcommands).map { |child| read(child) },
        subcommand_required: reader.boolean(:subcommand_required),
      }
    end
    private_class_method(:words)

    def self.parts(reader, where)
      {
        flags: reader.objects(:flags).map { |flag| Flag.read(flag, where) },
        groups: reader.objects(:groups).map { |group| Group.read(group, where) },
        examples: reader.objects(:examples).map { |example| Example.read(example, where) },
      }
    end
    private_class_method(:parts)
  end
end
