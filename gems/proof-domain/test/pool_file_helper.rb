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
end
