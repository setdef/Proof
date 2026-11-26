# frozen_string_literal: true

module Proof
  class ProjectFileChildren
    MEMBERS = { os: :os, label: :labels, artifact: :artifacts, cache: :caches }.freeze
    BUILDERS = {
      os: -> (names) { names.map { |name| OS.new(name:) } },
      label: -> (names) { LabelSet.new(labels: names.map { |name| Label.new(name:) }) },
      artifact: -> (paths) { paths.map { |path| PathPattern.new(path:) } },
      cache: -> (paths) { paths.map { |path| PathPattern.new(path:) } },
    }.freeze
    NAMES = MEMBERS.keys.map(&:to_s).freeze
    public_constant(:NAMES)
    private_constant(:MEMBERS, :BUILDERS)

    def initialize(refusal:)
      @refusal = refusal
    end

    def read(node)
      node.each_child { |child, first| check(node, child, first) }
      node.children_by_name.to_h { |name, child| pair(child, name.to_sym) }
    end

    private def check(parent, child, first)
      refuse_unknown(parent, child)
      @refusal.repeated_child(child, first) if first
      refuse_shape(child)
    end

    private def refuse_unknown(parent, child)
      @refusal.unknown_child(parent, child) unless NAMES.include?(child.name)
    end

    private def refuse_shape(child)
      @refusal.child_without_arguments(child) if child.arguments.empty?
      @refusal.child_with_more(child) unless child.arguments_only?
    end

    private def pair(child, key)
      [MEMBERS[key], @refusal.checking(child) { BUILDERS[key].call(child.arguments) }]
    end
  end
end
