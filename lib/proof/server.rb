# frozen_string_literal: true

module Proof
  module Server
    # The server's classes load OpenSSL, and some load Falcon, so each loads the first time something names it, and
    # `require "proof"` loads none of them.
    {
      CurrentPoolFile: "current_pool_file",
      Identity: "identity",
      IdentityError: "identity_error",
      IdentityFiles: "identity_files",
      IdentityReader: "identity_reader",
      IdentityRefusal: "identity_refusal",
      KeptFile: "kept_file",
      PoolFileWatch: "pool_file_watch",
    }.each { |name, file| autoload(name, File.join(__dir__.to_s, "server", "#{file}.rb")) }
  end
end
