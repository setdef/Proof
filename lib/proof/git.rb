# frozen_string_literal: true

require "open3"

module Proof
  class Git
    def self.cleared_environment
      ENV.keys.grep(/\AGIT_/).to_h { |name| [name, nil] }
    end

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
      environment = Git.cleared_environment.merge(env.transform_keys(&:to_s))
      Open3.capture3(environment, @program, *arguments, chdir: @folder, stdin_data: input)
    rescue Errno::ENOENT
      # A missing folder raises the same error as a missing program, so only a folder that exists means no git.
      raise unless File.directory?(@folder)

      raise(GitNotFoundError, "Proof found no program named #{@program}. Install Git, or fix PATH, and run again.")
    end
  end
end
