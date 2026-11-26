# frozen_string_literal: true

module DocExamples
  # What a run found: how many blocks ran, each skipped block with its reason,
  # and each failure.
  # steep:ignore:start
  class Report < Data.define(:ran, :skipped, :failures)
    # steep:ignore:end
    # The one report that holds what each of +reports+ found.
    def self.combine(reports)
      new(ran: reports.sum(&:ran), skipped: reports.flat_map(&:skipped), failures: reports.flat_map(&:failures))
    end

    # Whether every example that ran was right.
    def ok?
      failures.empty?
    end

    # The lines the task prints: the counts, then each skipped block.
    def summary
      ["Examples run: #{ran}. Examples skipped: #{skipped.size}.", *skipped.map { |line| "  skipped #{line}" }]
    end
  end
end
