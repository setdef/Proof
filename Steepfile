# frozen_string_literal: true

target :lib do
  signature "sig", "steep", "gems/proof-domain/sig", "gems/proof-domain/steep"
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
  library "open3"
end

# The domain gem is checked alone, with only its own signatures, so a type
# that names anything outside it is an error.
target :domain do
  signature "gems/proof-domain/sig", "gems/proof-domain/steep"
  check "gems/proof-domain/lib"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)
end

target :tasks do
  signature "tasks/sig"
  check "tasks/ruby_doc_comments.rb"
  check "tasks/doc_examples.rb"
  check "tasks/doc_examples"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library "ripper"
  library "json"
  library "open3"
  library "prism"
  library "tmpdir"
end
