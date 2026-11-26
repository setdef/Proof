# frozen_string_literal: true

module DocExamples
  # One fenced +ruby+ block in a page or in an RDoc comment: where it is, the
  # code in it, and why it is skipped when a skip marker comes before it.
  #
  # +line+ is the line of the first line of +code+ in the file, so a line
  # inside the block maps to +line+ plus its offset.
  # steep:ignore:start
  class Block < Data.define(:path, :line, :code, :skip_reason)
    # steep:ignore:end
    # The marker that opens a block meant to raise: the first line of the
    # block says which error it raises.
    ERROR_MARKER = "# Wrong: raises "
    private_constant(:ERROR_MARKER)

    # Whether a skip marker came before the block.
    def skipped?
      skip_reason.is_a?(String)
    end

    # The failure for a skip marker that gives no reason, or nil when the
    # block isn't skipped or the marker gives one.
    def missing_reason
      "#{place}: a skip-example marker needs a reason after the colon" if skip_reason == ""
    end

    # The line that reports a skipped block: its place, then its reason.
    def skip_line
      "#{place}: #{skip_reason}"
    end

    # The name of the error the block must raise, or nil for a block that
    # must run without one.
    def raises
      return unless code.start_with?(ERROR_MARKER)

      code.delete_prefix(ERROR_MARKER).lines.first.to_s.split.first.to_s
    end

    # The place of a line of the block, as "path:line". The first line is 1.
    def place(line_in_block = 1)
      "#{path}:#{line + line_in_block - 1}"
    end
  end
end
