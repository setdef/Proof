# frozen_string_literal: true

module Usage
  module Layout
    TABLE_WIDTH = 78
    private_constant(:TABLE_WIDTH)

    def self.wrap(words, width)
      words.gsub(/\s+/, " ").scan(/\S.{0,#{width - 2}}(?=\s|\z)|\S+/).map(&:to_s)
    end

    def self.paragraphs(text, width)
      # Text the spec already wraps keeps its lines, so only a line longer than the help's width is wrapped again.
      fitted = text&.lines&.flat_map { |line| (line.length > width) ? wrap(line, width) : [line.chomp] }
      fitted&.join("\n")
    end

    def self.table(title, rows)
      # OptionParser's summary doesn't wrap a description, indents a flag with no short name to line up with the
      # others, and moves a label wider than its column to a line of its own. It has no table of subcommands or
      # arguments either, so every table is laid out here.
      widths = rows.map { |label, _| label.length }
      gap = (widths.max || return) + 4
      [title, *rows.flat_map { |label, words| row(label, words, gap) }].join("\n")
    end

    def self.row(label, words, gap)
      first, *rest = wrap(words, TABLE_WIDTH - gap)
      [("  #{label}".ljust(gap) + first.to_s).rstrip, *rest.map { |line| "#{' ' * gap}#{line}" }]
    end
    private_class_method(:row)
  end
end
