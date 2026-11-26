# frozen_string_literal: true

require "json"

module Usage
  module Keys
    def self.check(object, where, keys)
      # A key the reader doesn't know, or a value it can't act on, would change what the spec means if it were
      # skipped, so each is refused by name, and the gem can learn it later without changing what it accepts now.
      object.each do |key, value|
        refusal = refusal("#{key}=#{JSON.generate(value)}", keys)
        raise(SpecError, "#{where} #{refusal}, which usage-rb doesn't support") if refusal
      end
    end

    def self.refusal(setting, keys)
      key, value = setting.split("=", 2)
      return if keys.include?(key) || keys.include?(setting)

      (keys.any? { |each| each.start_with?("#{key}=") }) ? "sets #{key} to #{value}" : "has #{key}"
    end
    private_class_method(:refusal)
  end
end
