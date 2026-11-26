# frozen_string_literal: true

module Proof
  module PoolFileForms
    SETTINGS = %i[budget keep-free share active-for withhold].freeze
    ALL = [
      PoolFileForm.new(name: :server, usage: "server port=7443", properties: %i[port]),
      PoolFileForm.new(
        name: :retention,
        usage: "retention runs=\"90d\" output=\"14d\" artifacts=\"7d\"",
        properties: %i[runs output artifacts]
      ),
      PoolFileForm.new(
        name: :limits, usage: "limits output=\"1GB\" artifacts=\"16GB\"", properties: %i[output artifacts]
      ),
      PoolFileForm.new(name: :defaults, usage: "defaults { budget \"100GB\" }", children: SETTINGS),
      PoolFileForm.new(
        name: :host,
        usage: "host nuc { runner nuc-linux; budget \"400GB\" }",
        arguments: 1..1,
        children: [:runner, *SETTINGS],
        needs: %i[runner],
        repeatable: true
      ),
      PoolFileForm.new(name: :runner, usage: "runner nuc-linux", arguments: 1.., repeatable: true),
      PoolFileForm.new(name: :budget, usage: "budget \"100GB\"", arguments: 1..1),
      PoolFileForm.new(name: :"keep-free", usage: "keep-free \"25GB\"", arguments: 1..1),
      PoolFileForm.new(
        name: :share, usage: "share cpus=2 memory=\"4GB\"", properties: %i[cpus memory], required: %i[cpus memory]
      ),
      PoolFileForm.new(name: :"active-for", usage: "active-for \"5m\"", arguments: 1..1),
      PoolFileForm.new(name: :withhold, usage: "withhold gpu desktop", arguments: 1..),
    ].freeze
    BY_NAME = ALL.to_h { |form| [form.name, form] }
    BY_NAME.freeze
    private_constant(:SETTINGS, :ALL, :BY_NAME)

    def self.[](name)
      BY_NAME[name]
    end

    def self.of(node)
      BY_NAME[node.name.to_sym]
    end
  end
end
