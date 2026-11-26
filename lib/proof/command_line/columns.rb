# frozen_string_literal: true

module Proof
  module CommandLine
    class Columns
      WIDTH = 78
      private_constant(:WIDTH)

      def self.wrap(words, width)
        words.gsub(/\s+/, " ").scan(/\S.{0,#{width - 2}}(?=\s|\z)|\S+/).map(&:to_s)
      end

      def self.paragraphs(text, width)
        fitted = text&.lines&.flat_map { |line| (line.length > width) ? wrap(line, width) : [line.chomp] }
        fitted&.join("\n")
      end

      def self.table(title, rows)
        new(title, rows).text unless rows.empty?
      end

      def initialize(title, rows)
        @title = title
        @rows = rows
        widths = rows.map { |row| row.label.length }
        @gap = (widths.max || 0) + 4
      end

      def text
        [@title, *@rows.flat_map { |entry| row(entry.label, entry.text) }].join("\n")
      end

      private def row(label, words)
        first, *rest = Columns.wrap(words, WIDTH - @gap)
        [("  #{label}".ljust(@gap) + first.to_s).rstrip, *rest.map { |line| "#{' ' * @gap}#{line}" }]
      end
    end
  end
end
