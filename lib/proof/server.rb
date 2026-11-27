# frozen_string_literal: true

module Proof
  module Server
    # The server's classes load OpenSSL, and some load Falcon, so each loads the first time something names it, and
    # `require "proof"` loads none of them. Each file holds the class its name gives, as `identity_error.rb` holds
    # `IdentityError`.
    %w[
      current_pool_file
      fibers
      https
      identity
      identity_error
      identity_files
      identity_reader
      identity_refusal
      kept_file
      listen_error
      paths
      pool_file_watch
      requests
      root
      service
      stop
      version_request
    ].each do |file|
      autoload(file.split("_").map(&:capitalize).join.to_sym, File.join(__dir__.to_s, "server", "#{file}.rb"))
    end

    def self.serve(home: Dir.home, err: $stderr, host: nil)
      Service.new(home:, err:, host:).serve
    end
  end
end
