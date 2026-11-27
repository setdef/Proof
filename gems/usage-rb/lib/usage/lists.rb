# frozen_string_literal: true

module Usage
  module Lists
    EXAMPLE_WIDTH = 70
    private_constant(:EXAMPLE_WIDTH)

    def self.examples(list)
      lines = list.flat_map { |example| example_lines(example) }
      ["Examples:", *lines].join("\n") unless lines.empty?
    end

    def self.commands(title, list)
      Layout.table(title, list.map { |command| [command.name, command.help.to_s] })
    end

    def self.arguments(list)
      Layout.table("Arguments:", list.map { |arg| [arg.to_s, arg.help.to_s] })
    end

    def self.flags(title, list)
      Layout.table(title, list.map { |flag| [label(flag), text(flag)] })
    end

    def self.exit_statuses(codes)
      Layout.table("Exit statuses:", codes.map { |code| [code.status.to_s, code.help] })
    end

    def self.example_lines(example)
      header = example.header
      lines = ["    $ #{example.code}", *Layout.wrap(example.help.to_s, EXAMPLE_WIDTH).map { |line| "    #{line}" }]
      header ? ["  #{header}", *lines] : lines
    end
    private_class_method(:example_lines)

    def self.label(flag)
      "#{flag.switches.join(', ')}#{" <#{flag.value}>" if flag.takes_value?}"
    end
    private_class_method(:label)

    def self.text(flag)
      choices = flag.choices
      values = choices.values
      "#{flag.help}#{" (#{choices.strict? ? 'one of' : 'such as'} #{values.join(', ')})" unless values.empty?}"
    end
    private_class_method(:text)
  end
end
