# frozen_string_literal: true

module Proof
  module CommandLine
    class Spec
      # steep:ignore:start
      class Command < Data.define(:node)
        # steep:ignore:end
        def name
          node.text("name").to_s
        end

        def path
          node.texts("full_cmd")
        end

        def help
          node.text("help")
        end

        def help_long
          node.text("help_long")
        end

        def args
          node.read_all("args", Arg)
        end

        def flags
          node.read_all("flags", Flag)
        end

        def subcommands
          node.read_members("subcommands", Command)
        end

        def groups
          node.read_all("groups", Group)
        end

        def subcommand_required?
          node.true?("subcommand_required")
        end

        def examples
          node.read_all("examples", Example)
        end

        def subcommand(word)
          subcommands.find { |child| child.name == word }
        end

        def follow(words)
          word, *rest = words
          return self unless word

          subcommand(word)&.follow(rest)
        end

        def own_flags
          flags.reject(&:global?)
        end

        def global_flags
          flags.select(&:global?)
        end
      end
    end
  end
end
