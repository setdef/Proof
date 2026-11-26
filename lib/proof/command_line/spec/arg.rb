# frozen_string_literal: true

module Proof
  module CommandLine
    class Spec
      # steep:ignore:start
      class Arg < Data.define(:node)
        # steep:ignore:end
        def name
          node.text("name").to_s
        end

        def required?
          node.true?("required")
        end

        def repeatable?
          node.true?("var")
        end

        def help
          node.text("help")
        end

        def to_s
          label = repeatable? ? "#{name}..." : name
          required? ? "<#{label}>" : "[#{label}]"
        end

        # Steep reports as missing the members that Data.define makes, and the signature declares each one.
      end
    end
  end
end
