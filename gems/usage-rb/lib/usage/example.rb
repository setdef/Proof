# frozen_string_literal: true

module Usage
  # steep:ignore:start
  class Example < Data.define(:code, :header, :help)
    # steep:ignore:end
    KEYS = %w[code header help lang=""].freeze
    private_constant(:KEYS)

    def self.read(object, parent)
      reader = Reader.new(object, "an example of #{parent}", KEYS)
      new(code: reader.text(:code).to_s, header: reader.text(:header), help: reader.text(:help))
    end
  end
end
