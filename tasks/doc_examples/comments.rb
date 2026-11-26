# frozen_string_literal: true

module DocExamples
  # The runs of comment lines in an +.rbs+ file. RDoc reads each run as a
  # Markdown text.
  module Comments
    # The runs of comment lines in +lines+, each as its line number in the file
    # and its lines without their comment marks.
    def self.runs(lines)
      commented = lines.each_with_index.select { |line, _| line.lstrip.start_with?("#") }
      commented.slice_when { |(_, before), (_, after)| after != before + 1 }
        .map { |run| text_of(run) }
    end

    # One run, as pairs of a line and its index, as the line number of its
    # first line and its lines without their comment marks.
    def self.text_of(run)
      [run.first.last + 1, run.map { |line, _| line.lstrip.delete_prefix("#").delete_prefix(" ") }]
    end
    private_class_method(:text_of)
  end
end
