# frozen_string_literal: true

require "open3"

module Proof
  class Git
    def initialize(folder:, program: "git")
      @folder = folder
      @program = program
    end

    def run(*arguments, env: {}, input: "")
      output, error, status = capture(arguments, env, input)
      return output if status.success?

      raise(GitFailedError.new(subcommand: arguments.first.to_s, status:, error_output: error))
    end

    private def capture(arguments, env, input)
      inherited = ENV.keys.grep(/\AGIT_/).to_h { |name| [name, nil] }
      variables = inherited.merge(env.transform_keys(&:to_s))
      Open3.capture3(variables, @program, *arguments, chdir: @folder, stdin_data: input)
    rescue Errno::ENOENT
      raise(GitNotFoundError, "Proof found no program named #{@program}. Install Git, or fix PATH, and run again.")
    end
  end
end
