# frozen_string_literal: true

# Builds the values that the pool file page's examples describe, so a test of a rule reads as the page does, without a
# reader of KDL.
module PoolFileHelper
  # The size that a pool file writes as this text.
  def size(text)
    Proof::Size.read(text, name: "size")
  end

  # The duration that a pool file writes as this text, in the units a host's `active-for` and a `poll` take.
  def duration(text)
    Proof::Duration.read(text, units: %i[s m h], name: "duration")
  end

  # The duration that `retention` writes as this text, in days.
  def days(text)
    Proof::Duration.read(text, units: %i[d], name: "retention")
  end

  # The CPUs and memory that `share cpus=N memory="SIZE"` gives.
  def share_of(cpus, memory)
    Proof::Resources.new(cpus:, megabytes: size(memory).megabytes)
  end

  # The settings of a host's entry or of `defaults`, from what the test names: `budget`, `keep_free`, and `active_for`
  # as the file writes them, `share` as CPUs and a size, and `withhold` as labels. What a test leaves out is not given.
  def host_settings(budget: nil, keep_free: nil, share: nil, active_for: nil, withhold: nil)
    Proof::HostSettings.new(
      budget: budget && size(budget),
      keep_free: keep_free && size(keep_free),
      share: share && share_of(*share),
      active_for: active_for && duration(active_for),
      withheld: withhold && Proof::LabelSet.of(*withhold)
    )
  end

  # A host's entry with this name and these runners, and the settings that `host_settings` builds.
  def host_entry(name, runners, **settings)
    Proof::HostEntry.new(name:, runners:, settings: host_settings(**settings))
  end

  # The `defaults` node of the page's "A complete example".
  def example_defaults
    host_settings(budget: "100GB", share: [2, "4GB"], active_for: "5m")
  end

  # The `nuc` entry of the page's "A complete example".
  def nuc_entry
    host_entry("nuc", %w[nuc-linux], budget: "400GB")
  end

  # The `pc` entry of the page's "A complete example".
  def pc_entry
    host_entry("pc", %w[pc-windows pc-wsl], budget: "250GB", share: [4, "16GB"], withhold: %w[gpu])
  end

  # A repository's entry with this name and URL, and these branches and tasks, as the page's examples write them.
  def repository_entry(name, url, branches:, tasks:, **optional)
    poll = optional[:poll]

    Proof::RepositoryEntry.new(name:, url:, branches:, tasks:, **optional, **(poll ? { poll: duration(poll) } : {}))
  end

  # The `lota` entry of the page's "A complete example".
  def lota_entry
    repository_entry(
      "lota",
      "https://github.com/setdef/Lota.git",
      credentials_file: "~/.config/proof/credentials/lota",
      branches: %w[trunk],
      tasks: %w[test package]
    )
  end
end
