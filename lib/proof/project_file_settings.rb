# frozen_string_literal: true

module Proof
  class ProjectFileSettings
    def initialize(refusal:)
      @refusal = refusal
      @properties = ProjectFileProperties.new(refusal:)
      @lists = ProjectFileLists.new(refusal:)
    end

    def read(node)
      single = @properties.read(node)
      listed = @lists.read(node)
      @refusal.checking(node) { TaskSettings.new(**single, **listed) }
    end
  end
end
