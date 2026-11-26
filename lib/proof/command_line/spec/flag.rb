# frozen_string_literal: true

module Proof
  module CommandLine
    class Spec
      # steep:ignore:start
      class Flag < Data.define(:node)
        # steep:ignore:end
        def name
          node.text("name").to_s
        end

        def short
          node.texts("short")
        end

        def long
          node.texts("long")
        end

        def value
          node.node("arg")&.text("name")
        end

        def repeatable?
          node.true?("var")
        end

        def choices
          node.node("arg")&.node("choices")&.texts("choices") || []
        end

        def strict?
          !node.node("arg")&.node("choices")&.false?("strict")
        end

        def requires
          node.texts("requires")
        end

        def global?
          node.true?("global")
        end

        def help
          node.text("help")
        end

        def takes_value?
          node.node("arg").is_a?(Node)
        end

        def switches
          short.map { |letter| "-#{letter}" } + long.map { |word| "--#{word}" }
        end
      end
    end
  end
end
