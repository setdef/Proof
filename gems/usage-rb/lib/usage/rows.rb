# frozen_string_literal: true

module Usage
  module Rows
    EXAMPLE_WIDTH = 70
    private_constant(:EXAMPLE_WIDTH)

    def self.examples(list)
      lines = list.flat_map { |example| example_lines(example) }
      ["Examples:", *lines].join("\n") unless lines.empty?
    end

    def self.flags(title, list)
      Layout.table(title, list.map { |flag| [label(flag), text(flag)] })
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
      "#{flag.help}#{" (#{flag.strict? ? 'one of' : 'such as'} #{choices.join(', ')})" unless choices.empty?}"
    end
    private_class_method(:text)
  end
end
