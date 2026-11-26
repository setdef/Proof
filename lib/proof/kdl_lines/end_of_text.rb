# frozen_string_literal: true

require "kdl"

module Proof
  module KdlLines
    module EndOfText
      REACH = 8
      private_constant(:REACH)

      def [](index)
        # In a block comment with no end, the gem's tokenizer reads nothing and moves on, forever. It makes more than
        # one tokenizer in a parse, and the tokenizer for a continued line is made inside the gem, so the check is
        # in the class and not in a parser's own tokenizer.
        # The gem's tokenizer looks at most four characters ahead, so a read past the text by more than REACH is a
        # tokenizer that has run off the end.
        raise_error("Unterminated multi-line comment") if index > @str.length + REACH
        super
      end
    end

    KDL::Tokenizer.prepend(EndOfText)
  end
end
