# frozen_string_literal: true

require "json"

module Usage
  module SpecFormat
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
      reader = Reader.new(json(text), Place::PROGRAM, KEYS)
      check_usage_version(reader.text(:min_usage_version))
      Spec.new(**described(reader), **parts(reader), **environment(reader))
    end

    def self.json(text)
      object = JSON.parse(text, symbolize_names: true)
      object.is_a?(Hash) ? object : raise(SpecError, "a usage spec is a JSON object, as usage generate json writes it")
    rescue JSON::ParserError => e
      raise(SpecError, "a usage spec is JSON, and this text isn't: #{e.message}")
    end
    private_class_method(:json)

    def self.check_usage_version(wanted)
      return unless wanted

      Place::PROGRAM.mistyped(:min_usage_version, "a version") unless Gem::Version.correct?(wanted)
      # A newer usage may write keys or values this gem has never seen, and would read differently.
      return if Gem::Version.new(wanted) <= Gem::Version.new(USAGE_VERSION)

      setting = "the program sets min_usage_version to #{wanted.inspect}"
      raise(SpecError, "#{setting}, which usage-rb doesn't support: it reads specs of usage #{USAGE_VERSION}")
    end
    private_class_method(:check_usage_version)

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
        examples: reader.parts(:examples, ExampleFormat),
        exit_codes: reader.parts(:exit_codes, ExitCodeFormat),
        commands: CommandTree.new(root: CommandFormat.read(reader.object(:cmd))),
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
