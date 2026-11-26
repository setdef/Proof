# frozen_string_literal: true

module Proof
  module RunIdText
    def self.read(text)
      fields(text.is_a?(String) ? text : "")
    rescue ArgumentError
      raise(InvalidRunIdError, format("a run ID looks like 20261125-0336-m3d8q, not %p", text))
    end

    def self.fields(text)
      minute = Time.new(text.sub(/\A(\d{4})(\d\d)(\d\d)-(\d\d)(\d\d).*/, '\1-\2-\3 \4:\5:00'), in: "UTC")
      # Time.new reads 20260230 as March 2, so the minute has to read back as written.
      prefix = minute.strftime("%Y%m%d-%H%M-")
      text.start_with?(prefix) ? { minute:, characters: text.delete_prefix(prefix) } : raise(ArgumentError)
    end
    private_class_method(:fields)
  end
  private_constant(:RunIdText)
end
