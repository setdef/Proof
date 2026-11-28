# frozen_string_literal: true

module Usage
  module Lists
    EXAMPLE_WIDTH = 70
    private_constant(:EXAMPLE_WIDTH)

    def self.examples(title, list)
      lines = list.flat_map { |example| example_lines(example) }
      [title, *lines].join("\n") unless lines.empty?
    end

    def self.commands(title, list)
      described(title, list, &:name)
    end

    def self.arguments(title, list)
      described(title, list, &:to_s)
    end

    def self.flags(title, list)
      Layout.table(title, list.map { |flag| [label(flag), text(flag)] })
    end

    def self.exit_statuses(title, codes)
      described(title, codes) { |code| code.status.to_s }
    end

    def self.described(title, list)
      Layout.table(title, list.map { |part| [yield(part), part.help.to_s] })
    end
    private_class_method(:described)

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
