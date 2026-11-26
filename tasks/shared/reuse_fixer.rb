# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
# SPDX-License-Identifier: MIT
#++

require "json"
require "open3"

# Adds missing SPDX headers, and puts the header of a Ruby file in the order
# AGENTS.md describes.
#
# Headers are tedious to write by hand, and a file without one fails
# <tt>reuse lint</tt>. This class asks reuse which files lack a header and
# annotates them with the license for their kind of file.
#
# === Examples
#
#   ReuseFixer.new.annotate_missing
#   ReuseFixer.new.normalize_ruby
class ReuseFixer
  COPYRIGHT = "setdef <kerrick@setdef.com>"
  CODE_LICENSE = "MIT"
  CODE_EXTENSIONS = %w[rb rbs rake gemspec toml yml yaml json lock].freeze
  DOC_LICENSE = "CC-BY-SA-4.0"
  DOC_EXTENSIONS = %w[md txt].freeze
  RUBY_GLOB = "**/*.{rb,rake,gemspec}"
  HEADER = /(# SPDX-FileCopyrightText:[^\n]+\n(?:#[^\n]*\n)*# SPDX-License-Identifier:[^\n]+\n)/
  MAGIC_COMMENT = /^# frozen_string_literal: true\n+/
  private_constant(
    :COPYRIGHT, :CODE_LICENSE, :CODE_EXTENSIONS, :DOC_LICENSE, :DOC_EXTENSIONS, :RUBY_GLOB, :HEADER, :MAGIC_COMMENT
  )

  # Annotates each file that <tt>reuse lint</tt> reports as missing a header.
  def annotate_missing
    puts("Checking for files missing REUSE headers...")
    missing = missing_files
    puts("All files have REUSE headers!") if missing.empty?
    missing.each { |file| annotate(file) }
  end

  # Rewrites each Ruby file's magic comment and SPDX header into the order
  # <tt>frozen_string_literal</tt>, blank line, <tt>#--</tt>, SPDX lines,
  # <tt>#++</tt>.
  def normalize_ruby
    fixed = ruby_files.sum { |file| normalize(file) }
    puts(fixed.zero? ? "All Ruby files properly normalized!" : "Fixed #{fixed} files.")
  end

  # Files that reuse reports as missing licensing information.
  private def missing_files
    output, = Open3.capture2("reuse", "lint", "--json")
    JSON.parse(output).dig("non_compliant", "missing_licensing_info")
  end

  # The license for a file with extension +extension+, or nil.
  private def license_for(extension)
    return CODE_LICENSE if CODE_EXTENSIONS.include?(extension)

    DOC_LICENSE if DOC_EXTENSIONS.include?(extension)
  end

  # Annotates +file+ with the license for its extension, if it has one.
  private def annotate(file)
    license = license_for(File.extname(file).delete("."))
    return puts("  Skipping #{file} (unknown extension)") unless license

    puts("  Annotating #{file} with #{license}")
    command = ["reuse", "annotate", "--license", license, "--copyright", COPYRIGHT, "--skip-existing", file]
    system(*command, exception: true)
  end

  # Ruby files outside vendor and tmp.
  private def ruby_files
    Dir.glob(RUBY_GLOB).grep_v(%r{\A(?:vendor|tmp)/})
  end

  # Rewrites +file+ when its header is out of order. Returns 1 when it did,
  # and 0 when it didn't.
  private def normalize(file)
    content = File.read(file)
    header = content[HEADER, 1]
    rebuilt = header && rebuild(content, header)
    return 0 if rebuilt.nil? || rebuilt == content

    File.write(file, rebuilt)
    puts("  Normalized #{file}")
    1
  end

  # +content+ with its magic comment and +header+ in the standard order.
  private def rebuild(content, header)
    body = content.sub(MAGIC_COMMENT, "").sub(/^#--\s*\n/, "").sub(header, "").sub(/^#\+\+\s*\n/, "")
    magic = content.match?(MAGIC_COMMENT) ? "# frozen_string_literal: true\n\n" : ""
    "#{magic}#--\n#{header}#++\n\n#{body.sub(/\A\n+/, '')}"
  end
end
