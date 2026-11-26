# frozen_string_literal: true

module Proof
  module CommandLine
    # steep:ignore:start
    class RunCommand < Data.define(
      :tasks,
      :script,
      :os,
      :label,
      :commit,
      :project,
      :cpus,
      :memory,
      :timeout,
      :empty,
      :keep,
      :input,
      :input_file,
      :download,
      :output,
      :detach,
      :json
    )
      # steep:ignore:end
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
    end
  end
end
