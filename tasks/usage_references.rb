# frozen_string_literal: true

require "open3"

# Finds the generated CLI references that no longer match the CLI spec.
#
# Two pages are generated from +proof.usage.kdl+, and a hand edit to either,
# or a spec change without a regeneration, leaves them wrong. usage 7.4.1 has
# no check mode, so this class generates the Markdown again and compares it
# with each page.
#
# === Examples
#
#   UsageReferences.stale  # => ["doc/reference/cli.md"]
class UsageReferences
  SPEC = "proof.usage.kdl"
  PAGES = %w[doc/reference/cli.md skills/proof/references/cli.md].freeze
  private_constant(:SPEC, :PAGES)

  # The commands that regenerate the pages, as they are written in AGENTS.md.
  def self.regenerate_commands
    PAGES.map { |page| "usage generate markdown --file #{SPEC} --out-file #{page}" }
  end

  # The pages that differ from what the spec generates now.
  def self.stale
    generated = generate
    PAGES.reject { |page| File.read(page) == generated }
  end

  # What <tt>usage generate markdown</tt> prints for the spec.
  def self.generate
    output, status = Open3.capture2("usage", "generate", "markdown", "--file", SPEC, "--out-file", "-")
    abort("usage generate markdown failed") unless status.success?
    output
  end
  private_class_method(:generate)
end
