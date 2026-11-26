# frozen_string_literal: true

require "proof/domain"

require_relative("proof/command_line")
require_relative("proof/committed_file")
require_relative("proof/file_error")
require_relative("proof/file_reading")
require_relative("proof/file_refusal")
require_relative("proof/git")
require_relative("proof/git_project")
require_relative("proof/kdl_node")
require_relative("proof/kdl_parser")
require_relative("proof/kdl_syntax_reason")
require_relative("proof/project_file_children")
require_relative("proof/project_file_error")
require_relative("proof/project_file_reader")
require_relative("proof/project_file_refusal")
require_relative("proof/project_file_settings")
require_relative("proof/project_file_settings_refusal")
require_relative("proof/task_reader")
require_relative("proof/version")
require_relative("proof/working_tree_commit")

module Proof
end
