# frozen_string_literal: true

require_relative("committed_file")

module Proof
  module FileReading
    def file_at(id, path)
      CommittedFile.new(git: Git.new(folder: root, program:), commit: commit_id(id), path:).text
    end
  end
end
