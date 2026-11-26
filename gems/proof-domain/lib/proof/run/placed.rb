# frozen_string_literal: true

require_relative("fact")

module Proof
  class Run
    class Placed < Data.define(:at, :host, :runner)
      include Fact

      def initialize(at:, host:, runner:)
        super(
          at:, host: Fact.name_of(host, "a placed run's host is a name, not %p"),
          runner: Fact.name_of(runner, "a placed run's runner is a name, not %p"))
      end

      def on?(host_name, runner_names)
        pairs = runner_names.map { |name| [host_name, name] }
        pairs.include?([host, runner])
      end
    end
  end
end
