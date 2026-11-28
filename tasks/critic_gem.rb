# frozen_string_literal: true

require "json"
require_relative("critic_faults")

# One gem of the repository, which the RubyCritic gate scores alone.
#
# A gem ships and changes on its own, so its score is the average over its own files. The average over the whole
# repository would let the files of one gem lift or sink the score of another.
#
# === Examples
#
#   CriticGem.in_repository(".").map(&:name)
#   # => ["proof", "proof-domain", "usage-rb"]
#   CriticGem.in_repository(".").first.paths
#   # => ["lib", "sig"]
class CriticGem < Data.define(:name, :paths)
  # The name of the gem at the root of the repository.
  ROOT_NAME = "proof"
  # The folders of a gem that RubyCritic scores.
  FOLDERS = %w[lib sig].freeze
  private_constant(:ROOT_NAME, :FOLDERS)

  # The gem at the root of the repository at +root+, then each folder of +gems+ that has a +lib+ folder, by name.
  # Each has the paths of its own +lib+ and +sig+, relative to +root+.
  def self.in_repository(root)
    folders = Dir.glob("gems/*", base: root).select { |folder| File.directory?(File.join(root, folder, "lib")) }
    [["", ROOT_NAME], *folders.map { |folder| [folder, File.basename(folder)] }].map do |folder, name|
      paths = FOLDERS.map { |kind| File.join(folder, kind).delete_prefix("/") }
      new(name:, paths: paths.select { |path| File.directory?(File.join(root, path)) })
    end
  end

  # One line for each fault in the +json+ report of RubyCritic on this gem, each starting with the gem's name: a
  # score under +floor+, a file rated below A, and a smell. Empty when the gem holds the gate.
  def faults(json, floor:)
    score = JSON.parse(json, symbolize_names: true)[:score]
    lines = CriticFaults.in_report(json)
    lines.unshift("the score is #{score}, under #{floor}.") if score < floor
    lines.map { |line| "#{name}: #{line}" }
  end
end
