# frozen_string_literal: true

require_relative("kdl_form")
require_relative("kdl_forms")

module Proof
  settings = %i[budget keep-free share active-for withhold].freeze
  PoolFileForms = KdlForms.new(
    top: %i[server retention limits defaults host repository],
    forms: [
      KdlForm.new(name: :server, usage: "server port=7443", properties: %i[port]),
      KdlForm.new(
        name: :retention,
        usage: "retention runs=\"90d\" output=\"14d\" artifacts=\"7d\"",
        properties: %i[runs output artifacts]
      ),
      KdlForm.new(name: :limits, usage: "limits output=\"1GB\" artifacts=\"16GB\"", properties: %i[output artifacts]),
      KdlForm.new(name: :defaults, usage: "defaults { budget \"100GB\" }", children: settings),
      KdlForm.new(
        name: :host,
        usage: "host nuc { runner nuc-linux; budget \"400GB\" }",
        arguments: 1..1,
        children: [:runner, *settings],
        needs: %i[runner],
        repeatable: true
      ),
      KdlForm.new(name: :runner, usage: "runner nuc-linux", arguments: 1.., repeatable: true),
      KdlForm.new(name: :budget, usage: "budget \"100GB\"", arguments: 1..1),
      KdlForm.new(name: :"keep-free", usage: "keep-free \"25GB\"", arguments: 1..1),
      KdlForm.new(
        name: :share, usage: "share cpus=2 memory=\"4GB\"", properties: %i[cpus memory], required: %i[cpus memory]
      ),
      KdlForm.new(name: :"active-for", usage: "active-for \"5m\"", arguments: 1..1),
      KdlForm.new(name: :withhold, usage: "withhold gpu desktop", arguments: 1..),
      KdlForm.new(
        name: :repository,
        usage: "repository lota url=\"https://github.com/setdef/Lota.git\" { branch trunk; task test }",
        arguments: 1..1,
        properties: %i[url],
        required: %i[url],
        children: %i[credentials-file branch task poll],
        needs: %i[branch task],
        repeatable: true
      ),
      KdlForm.new(
        name: :"credentials-file", usage: "credentials-file \"~/.config/proof/credentials/lota\"", arguments: 1..1
      ),
      KdlForm.new(name: :branch, usage: "branch trunk release", arguments: 1..),
      KdlForm.new(name: :task, usage: "task test package", arguments: 1.., repeatable: true),
      KdlForm.new(name: :poll, usage: "poll \"1m\"", arguments: 1..1),
    ].freeze
  )
  public_constant(:PoolFileForms)
end
