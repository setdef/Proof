# frozen_string_literal: true

#--
# SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
#
# SPDX-License-Identifier: MIT
#++

# SimpleCov starts before anything from lib loads, so it sees every line.
require "simplecov"

SimpleCov.start do
  # A deprecated SimpleCov setting raises instead of warning.
  deprecations(:raise)
  cover("lib/**/*.rb")
  enable_coverage(:branch)
  minimum_coverage(line: 100, branch: 100)
  coverage(:line) { minimum(100, per: :file) }
  coverage(:branch) { minimum(100, per: :file) }
  refuse_coverage_drop
end

require "minitest/autorun"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "proof"
