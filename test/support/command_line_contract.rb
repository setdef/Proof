# frozen_string_literal: true

require "json"
require "open3"

# What the contract test compares between `proof`'s parser and `usage explain`: how a command line parsed.
module CommandLineContract
  # One command line's outcome: refused, a request for help, or accepted as a command with flags and arguments.
  Outcome = Data.define(:kind, :command, :flags, :args)
  public_constant(:Outcome)

  REFUSED = Outcome.new(kind: :refused, command: [], flags: {}, args: {})
  HELP = Outcome.new(kind: :help, command: [], flags: {}, args: {})
  public_constant(:REFUSED, :HELP)
end
