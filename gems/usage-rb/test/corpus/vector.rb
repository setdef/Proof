# frozen_string_literal: true

require "json"
require_relative("reading")

# One vector of usage's argv conformance corpus: a spec, a command line, and what usage's grammar says reading them
# gives. It runs the vector against the gem and says how the gem's answer compares.
class CorpusVector
  FOLDER = File.expand_path("vectors", __dir__)
  public_constant(:FOLDER)

  # Every vector of the fixture, in the order of its files.
  def self.all
    Dir[File.join(FOLDER, "*.json")].flat_map do |file|
      JSON.parse(File.read(file), symbolize_names: true)[:vectors].map { |hash| new(hash) }
    end
  end

  attr_reader(:id)

  # A vector as the fixture's JSON holds it, with its keys as symbols.
  def initialize(hash)
    @id = hash[:id]
    @spec_json = JSON.generate(hash[:spec_json])
    @argv = hash[:argv]
    @expected = hash[:expect]
  end

  # `:refused` when the gem refuses the vector's spec, `:agrees` when the gem reads the command line as the corpus
  # says, and `:differs` otherwise.
  def verdict
    answer = answer(Usage::Spec.read(@spec_json))
    (answer == expected) ? :agrees : :differs
  rescue Usage::SpecError
    :refused
  end

  # What the corpus says: an error, whose class the gem doesn't name, or what the command line binds.
  private def expected
    @expected.key?(:error) ? { error: true } : { ok: pruned(@expected[:ok]) }
  end

  # What the gem reads the command line as, in the corpus's terms.
  private def answer(spec)
    parsed = Usage::Parser.new(spec).parse(@argv)
    parsed.help? ? { help: true } : { ok: pruned(CorpusReading.new(spec, parsed).to_h) }
  rescue Usage::CommandLineError
    { error: true }
  end

  # The binding without what is empty, since the corpus leaves out what is unset.
  private def pruned(binding)
    binding.reject { |_, value| value.nil? || value.empty? }
  end
end
