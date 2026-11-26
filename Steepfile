# frozen_string_literal: true

target :lib do
  signature "sig", "steep", "gems/proof-domain/sig", "gems/proof-domain/steep", "gems/usage-rb/sig"
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
  library "optparse"
  library "did_you_mean"
  library "open3"
  library "tmpdir"
end

# The domain gem is checked alone, with only its own signatures, so a type
# that names anything outside it is an error.
target :domain do
  signature "gems/proof-domain/sig", "gems/proof-domain/steep"
  check "gems/proof-domain/lib"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)
end

# The usage gem is checked alone too, with only its own signatures and the
# standard library it loads, so it can name nothing of Proof's.
target :usage do
  signature "gems/usage-rb/sig"
  check "gems/usage-rb/lib"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library "json"
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
