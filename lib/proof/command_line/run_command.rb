# frozen_string_literal: true

module Proof
  module CommandLine
    class RunCommand < Data.define(
      :tasks,
      :script,
      :script_words,
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
      # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      # @dynamic tasks, script, script_words, os, label, commit, project, cpus, memory, timeout
      # @dynamic empty, keep, input, input_file, download, output, detach, json, initialize
    end
  end
end
