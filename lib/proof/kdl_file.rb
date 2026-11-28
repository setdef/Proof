# frozen_string_literal: true

module Proof
  class KdlFile < Data.define(:path, :error, :forms, :refusal_class)
    def refusal
      refusal_class.new(path:, error:, messages: refusal_class.messages, forms:)
    end

    def nodes_by_name(text, refusal:)
      nodes = KdlParser.parse(text, path:, error:)
      KdlFormCheck.new(forms:, refusal:).check(nodes).group_by { |node| node.name.to_sym }
    end

    # @dynamic path, error, forms, refusal_class
  end
end
