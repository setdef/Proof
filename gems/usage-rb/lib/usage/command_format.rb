# frozen_string_literal: true

require_relative("named_format")

module Usage
  module CommandFormat
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
      reader = Reader.new(object, place(object[:full_cmd]), KEYS)
      command = Command.new(**NamedFormat.name_and_help(reader), **parts(reader))
      # A word after a command with both would be an argument or a subcommand's name, and usage decides by rules the
      # parser doesn't follow.
      reader.unsupported("has both arguments and subcommands") unless
        command.args.empty? || command.subcommands.empty?

      command
    end

    def self.place(words)
      words.is_a?(Array) ? Place.command(words) : Place::PROGRAM
    end
    private_class_method(:place)

    def self.parts(reader)
      {
        path: reader.texts(:full_cmd),
        args: reader.parts(:args, ArgFormat),
        flags: reader.parts(:flags, FlagFormat),
        groups: reader.parts(:groups, GroupFormat),
        examples: reader.parts(:examples, ExampleFormat),
        subcommands: reader.members(:subcommands).map { |child| read(child) },
        subcommand_required: reader.boolean(:subcommand_required),
      }
    end
    private_class_method(:parts)
  end
end
