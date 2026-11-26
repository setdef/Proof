# frozen_string_literal: true

require "json"

module Proof
  module CommandLine
    # steep:ignore:start
    class Spec < Data.define(:node)
      # steep:ignore:end
      PATH = File.join(File.dirname(__FILE__), "spec.json")
      public_constant(:PATH)

      def self.load
        parse(File.read(PATH))
      end

      def self.parse(text)
        new(Node.new(JSON.parse(text)))
      end

      def bin
        node.text("bin").to_s
      end

      def about
        node.text("about").to_s
      end

      def about_long
        node.text("about_long")
      end

      def after_help
        node.text("after_help_long")
      end

      def examples
        node.read_all("examples", Example)
      end

      def exit_codes
        node.read_all("exit_codes", ExitCode)
      end

      def root
        Command.new(node.node("cmd") || Node.new({}))
      end

      def command(path)
        root.follow(path)
      end
    end
  end
end

# The parts nest inside Spec, so they load after it: Ruby refuses to reopen a class with a superclass it
# first saw without one.
require_relative("spec/arg")
require_relative("spec/command")
require_relative("spec/example")
require_relative("spec/exit_code")
require_relative("spec/flag")
require_relative("spec/group")
require_relative("spec/node")
