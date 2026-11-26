# frozen_string_literal: true

# Builds the values that the project file page's examples describe, so a test of a
# rule reads as the page does, without a reader of KDL.
module ProjectFileHelper
  # The operating systems with these names.
  def oses(*names)
    names.map { |name| Proof::OS.new(name:) }
  end

  # The path patterns with these paths.
  def paths(*paths)
    paths.map { |path| Proof::PathPattern.new(path:) }
  end

  # Settings that a flag, an entry, or the defaults give, from what the test
  # names: `os`, `label`, `cpus`, `memory` (a size as a file writes it),
  # `timeout` (a duration), `artifact`, and `cache`.
  def given(**settings)
    Proof::TaskSettings.new(**given_values(settings), **given_lists(settings))
  end

  # The single settings of `given`, as `Proof::TaskSettings` takes them.
  def given_values(settings)
    memory, timeout = settings.values_at(:memory, :timeout)
    {
      cpus: settings[:cpus],
      megabytes: memory && Proof::Resources.request(cpus: 1, memory:).megabytes,
      time_limit: timeout && Proof::TimeLimit.read(timeout),
    }
  end

  # The lists of `given`, as `Proof::TaskSettings` takes them.
  def given_lists(settings)
    {
      os: settings[:os]&.then { |names| oses(*names) },
      labels: settings[:label]&.then { |names| Proof::LabelSet.of(*names) },
      artifacts: settings[:artifact]&.then { |patterns| paths(*patterns) },
      caches: settings[:cache]&.then { |patterns| paths(*patterns) },
    }
  end

  # A task entry with this name, this command, and these settings.
  def entry(name, command = nil, **settings)
    Proof::TaskEntry.new(name:, command:, settings: given(**settings))
  end

  # The project file of the page's "A complete example".
  def complete_example
    Proof::ProjectFile.new(
      defaults: given(os: %w[linux macos windows], cpus: 4, memory: "8GB", timeout: "45m", cache: ["tmp/engine/build"]),
      entries: [
        entry("test", label: ["desktop"]),
        entry("package", artifact: ["pkg/*.gem"]),
        entry("docs", "bundle exec rake rdoc", os: ["linux"], artifact: ["doc/api/**"]),
      ]
    )
  end

  # The settings of a run of these tasks, from this project file and these flags.
  def resolve(project_file, *names, **flags)
    Proof::SettingsResolver.new(project_file:, flags: given(**flags)).resolve(names)
  end

  # A hash from each task name to its command, from pairs of the two, as a run holds them.
  def named(*pairs)
    pairs.to_h
  end

  # What a run gets, as a hash of what the project file page's tables list.
  def summary(run)
    settings = run.settings
    {
      os: os_names(settings.os),
      labels: label_names(settings.labels),
      cpus: settings.cpus,
      megabytes: settings.megabytes,
      seconds: settings.time_limit.seconds,
      **given_paths(settings),
      commands: run.commands,
    }
  end

  # The artifacts and caches of settings, as sorted paths.
  def given_paths(settings)
    { artifacts: path_names(settings.artifacts), caches: path_names(settings.caches) }
  end

  # What the complete example's `defaults` node gives every task, apart from its operating systems.
  EXAMPLE_DEFAULTS = { cpus: 4, megabytes: 8192, seconds: 2700, caches: ["tmp/engine/build"] }.freeze
  public_constant(:EXAMPLE_DEFAULTS)

  # Proof's built-in defaults, with what a test says differs: "Any operating
  # system, 2 CPUs, 4 GB, 60 minutes", and no label, artifact, or cache.
  def expected(**differences)
    nothing = { labels: [], artifacts: [], caches: [] }
    { os: %w[linux macos windows], cpus: 2, megabytes: 4096, seconds: 3600, **nothing, **differences }
  end

  # The names of the operating systems in a set, in order, as the page writes them.
  def os_names(oses)
    oses.sort_by(&:to_s).map(&:to_s)
  end

  # The paths in a set of path patterns, sorted.
  def path_names(patterns)
    patterns.sort_by(&:path).map(&:path)
  end

  # The labels in a label set, as written, sorted.
  def label_names(label_set)
    label_set.labels.sort_by(&:to_s).map(&:to_s)
  end
end
