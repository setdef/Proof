# frozen_string_literal: true

require_relative("kdl_form")
require_relative("kdl_forms")

module Proof
  settings = { properties: %i[cpus memory timeout], children: %i[os label artifact cache] }.freeze
  ProjectFileForms = KdlForms.new(
    top: %i[defaults task],
    forms: [
      KdlForm.new(name: :defaults, usage: "defaults cpus=4", **settings),
      KdlForm.new(name: :task, usage: "task test", arguments: 1..2, repeatable: true, **settings),
      KdlForm.new(name: :os, usage: "os linux macos windows", arguments: 1..),
      KdlForm.new(name: :label, usage: "label desktop", arguments: 1..),
      KdlForm.new(name: :artifact, usage: "artifact \"pkg/*.gem\"", arguments: 1..),
      KdlForm.new(name: :cache, usage: "cache \"tmp/engine/build\"", arguments: 1..),
    ].freeze
  )
  public_constant(:ProjectFileForms)
end
