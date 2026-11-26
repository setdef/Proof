# frozen_string_literal: true

module Proof
  class ProjectFileLists
    KEYS = { os: :os, label: :labels, artifact: :artifacts, cache: :caches }.freeze
    BUILDERS = {
      os: -> (names) { names.map { |name| OS.new(name:) } },
      label: -> (names) { LabelSet.new(labels: names.map { |name| Label.new(name:) }) },
      artifact: -> (paths) { paths.map { |path| PathPattern.new(path:) } },
      cache: -> (paths) { paths.map { |path| PathPattern.new(path:) } },
    }.freeze
    private_constant(:KEYS, :BUILDERS)

    def initialize(refusal:)
      @refusal = refusal
      @children = ProjectFileChildren.new(refusal:)
    end

    def read(node)
      @children.refuse_mistakes_in(node)
      node.children_by_name.to_h { |name, child| pair(child, name.to_sym) }
    end

    private def pair(child, key)
      [KEYS[key], @refusal.checking(child) { BUILDERS[key].call(child.arguments) }]
    end
  end
end
