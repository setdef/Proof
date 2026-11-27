# frozen_string_literal: true

module Usage
  module NamedFormat
    def self.name_and_help(reader)
      { name: reader.text(:name).to_s, help: reader.text(:help), help_long: reader.text(:help_long) }
    end
  end
end
