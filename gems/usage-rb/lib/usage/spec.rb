# frozen_string_literal: true

require "json"

module Usage
  # steep:ignore:start
  class Spec < Data.define(
    :bin,
    :about,
    :about_long,
    :after_help,
    :examples,
    :exit_codes,
    :root,
    :env_prefix,
    :env_allowed
  )
    # steep:ignore:end
    KEYS = %w[
      name
      bin
      version
      author
      license
      repository
      min_usage_version
      about
      about_long
      after_help_long
      examples
      exit_codes
      cmd
      unknown_env
      unknown_flags="error"
      usage=""
      complete={}
      config={"props":{},"sources":{},"files":[]}
    ].freeze
    ENV_KEYS = %w[prefix allow].freeze
    private_constant(:KEYS, :ENV_KEYS)

    def self.read(text)
      reader = Reader.new(json(text), "the program", KEYS)
      new(**described(reader), **parts(reader), **environment(reader))
    end

    def command(path)
      root.follow(path)
    end

    def self.json(text)
      object = JSON.parse(text, symbolize_names: true)
      object.is_a?(Hash) ? object : raise(SpecError, "a usage spec is a JSON object, as usage generate json writes it")
    rescue JSON::ParserError => e
      raise(SpecError, "a usage spec is JSON, and this text isn't: #{e.message}")
    end
    private_class_method(:json)

    def self.described(reader)
      {
        bin: reader.text(:bin).to_s,
        about: reader.text(:about).to_s,
        about_long: reader.text(:about_long),
        after_help: reader.text(:after_help_long),
      }
    end
    private_class_method(:described)

    def self.parts(reader)
      {
        examples: reader.objects(:examples).map { |example| Example.read(example, "the program") },
        exit_codes: reader.objects(:exit_codes).map { |code| ExitCode.read(code) },
        root: CommandReader.read(reader.object(:cmd)),
      }
    end
    private_class_method(:parts)

    def self.environment(reader)
      env = reader.nested(:unknown_env, ENV_KEYS)
      { env_prefix: env&.text(:prefix), env_allowed: env&.texts(:allow) || [] }
    end
    private_class_method(:environment)
  end
end
