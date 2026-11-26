# frozen_string_literal: true

module Proof
  # steep:ignore:start
  class KdlForms < Data.define(:top, :forms)
    # steep:ignore:end
    def [](name)
      forms.find { |form| form.name == name }
    end

    def of(node)
      by_name = forms.to_h { |form| [form.name, form] }
      by_name[node.name.to_sym]
    end

    def top?(node)
      top.include?(node.name.to_sym)
    end

    def once?(node)
      !of(node).repeatable
    end
  end
end
