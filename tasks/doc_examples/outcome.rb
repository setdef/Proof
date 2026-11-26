# frozen_string_literal: true

module DocExamples
  # Runs one block and judges how it ended: whether it raised an error, and
  # whether the block was meant to.
  module Outcome
    # The failure line for a block that was run in +scope+, a Binding, or nil
    # when it ended as it should. A block that names an error must raise it,
    # and any other block must raise nothing.
    def self.of(scope, entry)
      problem(entry, raised_by(scope, entry))
    end

    # The error a block raises when it runs in +scope+, or nil. An example may
    # raise a ScriptError or call +exit+, and each is a failure of that example
    # and not of the process that runs it.
    def self.raised_by(scope, entry)
      scope.eval(entry[:code], entry[:path], entry[:line])
      nil
    rescue StandardError, ScriptError, SystemExit, SecurityError => e
      e
    end
    private_class_method(:raised_by)

    # The failure line for a block that raised +error+, or nil for none.
    def self.problem(entry, error)
      name = entry[:raises]
      return unexpected(entry, error) unless name

      kind = error_class(name)
      kind ? judge(entry, kind, error) : "#{entry.values_at(:path, :line).join(':')}: `#{name}` is not an error class"
    end
    private_class_method(:problem)

    # The failure line for a block that raised +error+, or nil for none.
    def self.unexpected(entry, error)
      "#{place(entry, error)}: raised #{error.class}: #{error.message}" if error
    end
    private_class_method(:unexpected)

    # The failure line for a block that must raise +kind+, or nil when it does.
    def self.judge(entry, kind, error)
      name = entry[:raises]
      return "#{entry.values_at(:path, :line).join(':')}: expected #{name} to be raised, but nothing was" unless error
      return if error.is_a?(kind)

      "#{place(entry, error)}: expected #{name} to be raised, but #{error.class} was: #{error.message}"
    end
    private_class_method(:judge)

    # The error class a name gives, or nil when it names no error class.
    def self.error_class(name)
      found = Object.const_get(name)
      found if found.is_a?(Class) && found <= Exception
    rescue NameError
      nil
    end
    private_class_method(:error_class)

    # The place in the file that +error+ came from in the block, or the block's
    # first line when the error doesn't say.
    def self.place(entry, error)
      path, line = entry.values_at(:path, :line)
      from = error.backtrace_locations.to_a.find { |location| location.path == path }
      "#{path}:#{from&.lineno || line}"
    end
    private_class_method(:place)
  end
end
