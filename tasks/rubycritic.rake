# frozen_string_literal: true

require_relative("critic_gem")

# The floor for each gem's RubyCritic score. It may rise, never fall.
RUBYCRITIC_MINIMUM_SCORE = 95
RUBYCRITIC_REPORT_DIR = "tmp/rubycritic"

# RubyCritic runs once for each gem, in a shell so that it can't exit the rake process, then the task reads its JSON
# report: the gem's score is at least the floor, every file is rated A, and no smell from reek or flay is left. The
# task runs every gem before it fails, so one run names each gem that is short.
desc "Run RubyCritic on each gem alone: a score of at least #{RUBYCRITIC_MINIMUM_SCORE}, every file rated A, no smells"
task :rubycritic do
  faults = CriticGem.in_repository(Dir.pwd).flat_map do |critic_gem|
    report_dir = File.join(RUBYCRITIC_REPORT_DIR, critic_gem.name)
    report = File.join(report_dir, "report.json")
    FileUtils.rm_f(report)
    system("bundle", "exec", "rubycritic", "--no-browser", "--format", "json", "--path", report_dir, *critic_gem.paths)
    abort("RubyCritic wrote no report for #{critic_gem.name}.") unless File.exist?(report)

    critic_gem.faults(File.read(report), floor: RUBYCRITIC_MINIMUM_SCORE)
  end
  lines = faults.map { |fault| "  #{fault}" }
  abort("RubyCritic faults:\n#{lines.join("\n")}") unless lines.empty?
end
