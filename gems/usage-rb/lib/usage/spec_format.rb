# frozen_string_literal: true

require_relative("keys")
require "json"

module Usage
  module SpecFormat
    KEYS = Keys.new(
      read: %i[
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
      ],
      defaults: { unknown_flags: "error", usage: "", complete: {}, config: { props: {}, sources: {}, files: [] } }
    )
    ENV_KEYS = Keys.new(read: %i[prefix allow])
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
        after_help_long: reader.text(:after_help_long),
      }
    end
    private_class_method(:described)

    def self.parts(reader)
      {
        examples: reader.parts(:examples, ExampleFormat),
        commands: CommandTree.new(root: program(reader)),
      }
    end
    private_class_method(:parts)

    def self.program(reader)
      root = CommandFormat.read(reader.object(:cmd), Place::PROGRAM)
      # usage writes the program's statuses beside its commands, and none in its `cmd`, so a list there would be a
      # second one that usage never folds.
      reader.unsupported("has exit_codes in cmd") unless root.exit_codes.empty?

      root.with(exit_codes: reader.parts(:exit_codes, ExitCodeFormat))
    end
    private_class_method(:program)

    def self.environment(reader)
      env = reader.nested(:unknown_env, ENV_KEYS)
      { env_prefix: env&.text(:prefix), env_allowed: env&.texts(:allow) || [] }
    end
    private_class_method(:environment)
  end
end
