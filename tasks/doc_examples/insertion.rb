# frozen_string_literal: true

require_relative("child")

module DocExamples
  # Inserts the checks that compare a statement's value with a +# =>+ comment.
  # The insertions add no line, so every line stays where it was.
  module Insertion
    # The two insertions, each a byte offset and text, that wrap +target+ in a
    # check of its value against +expected+, a source text, for the comment at
    # +place+.
    def self.wrap(target, expected, place)
      location = target.location
      [
        [location.start_offset, "#{Child::LOCAL}.check(("],
        [location.end_offset, "), #{expected.dump}, #{place.dump})"],
      ]
    end

    # +code+ with each text inserted at its byte offset.
    def self.apply(code, edits)
      edits.sort_by(&:first).reverse_each.with_object(code.dup) do |(offset, text), result|
        result.bytesplice(offset, 0, text)
      end
    end
  end
end
