# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
# SPDX-License-Identifier: MIT
#++

require "rdoc/task"

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = ENV.fetch("RDOC_OUTPUT", "tmp/rdoc")
  rdoc.rdoc_files.include("lib/**/*.rb")
end

# Import shared quality tasks (owned by ruby_quality) plus per-repo tasks.
Dir.glob("tasks/**/*.rake").each { |r| import(r) }

# Default runs gates only, never fixers.
desc "Run every gate"
task default: %w[test:ruby rubocop rubycritic steep reuse:lint rdoc:coverage usage:lint usage:references]
