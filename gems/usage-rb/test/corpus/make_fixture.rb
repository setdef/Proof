# frozen_string_literal: true

# Writes the corpus fixture: every vector of usage's argv conformance corpus, with the spec of each as `usage generate
# json` writes it. Run it with a checkout of usage at the tag to take, and `usage` on the path:
#
#   ruby gems/usage-rb/test/corpus/make_fixture.rb PATH_TO_USAGE_CHECKOUT
require "fileutils"
require "json"
require "open3"
require "tmpdir"

# Turns the KDL spec of a vector into the JSON that the gem reads.
module SpecJson
  # The JSON, parsed, that `usage generate json` writes for `kdl`.
  def self.of(kdl)
    Dir.mktmpdir do |dir|
      file = File.join(dir, "spec.usage.kdl")
      File.write(file, kdl)
      out, err, status = Open3.capture3("usage", "generate", "json", "--file", file)
      abort("usage refused a spec: #{err}") unless status.success?

      JSON.parse(out)
    end
  end
end

checkout, = ARGV
abort("usage: make_fixture.rb PATH_TO_USAGE_CHECKOUT") unless checkout

target = File.join(__dir__, "vectors")
FileUtils.rm_rf(target)
FileUtils.mkdir_p(target)
Dir[File.join(checkout, "corpus", "*.json")].each do |source|
  document = JSON.parse(File.read(source))
  document["vectors"].each { |vector| vector["spec_json"] = SpecJson.of(vector["spec"]) }
  File.write(File.join(target, File.basename(source)), "#{JSON.pretty_generate(document)}\n")
end
