# frozen_string_literal: true

require "open3"

# Finds the files generated from the CLI spec that no longer match it.
#
# Three files are generated from +proof.usage.kdl+: two Markdown references,
# and the JSON that the command line reads to print help. A hand edit to any
# of them, or a spec change without a regeneration, leaves it wrong. usage
# 7.4.1 has no check mode, so this class generates each one again and
# compares it with the file.
#
# === Examples
#
#   UsageReferences.stale  # => ["doc/reference/cli.md"]
class UsageReferences
  SPEC = "proof.usage.kdl"
  # Each generated file, with the +usage generate+ format that makes it.
  GENERATED = [
    ["doc/reference/cli.md", "markdown"],
    ["skills/proof/references/cli.md", "markdown"],
    ["lib/proof/command_line/spec.json", "json"],
  ].freeze
  private_constant(:SPEC, :GENERATED)

  # The commands that regenerate the files, as they are written in AGENTS.md.
  def self.regenerate_commands
    GENERATED.map do |path, format|
      "usage generate #{format} --file #{SPEC}#{(format == 'json') ? " > #{path}" : " --out-file #{path}"}"
    end
  end

  # The files that differ from what the spec generates now.
  def self.stale
    GENERATED.filter_map { |path, format| path unless File.read(path) == generate(format) }
  end

  # What <tt>usage generate FORMAT</tt> prints for the spec.
  def self.generate(format)
    # The Markdown format takes --out-file, and the JSON format prints to standard output only.
    destination = (format == "markdown") ? %w[--out-file -] : []
    output, status = Open3.capture2("usage", "generate", format, "--file", SPEC, *destination)
    abort("usage generate #{format} failed") unless status.success?
    output
  end
  private_class_method(:generate)
end
