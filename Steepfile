# frozen_string_literal: true

# SPDX-FileCopyrightText: 2026 setdef <kerrick@setdef.com>
# SPDX-License-Identifier: MIT

target :lib do
  signature "sig"
  check "lib"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library "json"
  library "pathname"
  library "fileutils"
  library "minitest"
  library "date"
  library "timeout"
  library "uri"
  library "stringio"
  library "securerandom"
  library "erb"
end
