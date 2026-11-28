# frozen_string_literal: true

# Steep loads every target's signatures into every other target, so a library
# that any signature names has to load in every target. A target that lacks one
# fails to build its types, and Steep then checks none of its files and reports
# no error. A library goes in this list, once, for all of them.
libraries = %w[
  date
  did_you_mean
  erb
  fileutils
  json
  minitest
  open3
  openssl
  optparse
  pathname
  securerandom
  socket
  stringio
  timeout
  tmpdir
  uri
].freeze

target :lib do
  signature "sig", "steep", "gems/proof-domain/sig", "gems/proof-domain/steep", "gems/usage-rb/sig"
  check "lib"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library(*libraries)
end

# The domain gem is checked with its own signatures, and Steep loads the
# others beside them.
target :domain do
  signature "gems/proof-domain/sig", "gems/proof-domain/steep"
  check "gems/proof-domain/lib"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library(*libraries)
end

# The usage gem is checked with its own signatures, and Steep loads the others
# beside them.
target :usage do
  signature "gems/usage-rb/sig"
  check "gems/usage-rb/lib"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library(*libraries)
end

target :tasks do
  signature "tasks/sig", "sig/proof/git.rbs", "gems/proof-domain/sig/proof/errors.rbs"
  check "tasks/ruby_doc_comments.rb"
  check "tasks/doc_examples.rb"
  check "tasks/doc_examples"
  check "tasks/release_version.rb"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.all_error)

  library(*libraries)
  library "prism"
  library "ripper"
end
