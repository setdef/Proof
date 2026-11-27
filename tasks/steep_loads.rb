# frozen_string_literal: true

require "steep"

# Finds the Steep targets that fail to load.
#
# Steep loads each target's signatures into every other target. A signature
# that names a type from a library that one target doesn't load, such as
# +OptionParser+ without +library "optparse"+, leaves that target unable to
# build its types. Steep then checks none of the target's files, reports no
# error, and ends with "No type error detected". This class loads each
# target's signatures as Steep does and names each target that fails, with
# the first diagnostic.
#
# === Examples
#
#   SteepLoads.failures(".")
#   # => ["domain fails to load: Cannot find type `OptionParser` (sig/proof/a.rbs:3)"]
class SteepLoads
  # One line for each target of the Steepfile in +root+ that fails to load.
  # Empty when every target loads.
  def self.failures(root)
    base = Pathname(root)
    project = Steep::Project.new(steepfile_path: base.join("Steepfile").expand_path)
    Steep::Project::DSL.parse(project, base.join("Steepfile").read)
    signatures = signature_texts(project, base)
    project.targets.filter_map { |target| failure(project, target, signatures) }
  end

  # The text of each signature file under +base+ that a target owns, by its
  # path from +base+.
  def self.signature_texts(project, base)
    base.glob("**/*.rbs").to_h { |path| [path.relative_path_from(base), path.read] }
      .select { |path, _| project.target_for_signature_path(path) }
  end
  private_class_method(:signature_texts)

  # The line for +target+, or nothing when it loads. The signatures it sees
  # are its own and every other target's that isn't unreferenced.
  def self.failure(project, target, signatures)
    service = loaded_service(project, target, signatures)
    return if service.current_subtyping

    "#{target.name} fails to load: #{first_diagnostic(service)}"
  end
  private_class_method(:failure)

  # The signature service of +target+, with the signatures it sees.
  def self.loaded_service(project, target, signatures)
    loader = Steep::Project::Target.construct_env_loader(options: target.options, project:)
    service = Steep::Services::SignatureService.load_from(loader, implicitly_returns_nil: target.implicitly_returns_nil)
    seen = signatures.select do |path, _|
      owner = project.target_for_signature_path(path)
      owner == target || !owner.unreferenced
    end
    service.update(seen.transform_values { |text| [Steep::Services::ContentChange.string(text)] })
    service
  end
  private_class_method(:loaded_service)

  # The message of the first diagnostic that the service's status holds, with
  # where it is.
  def self.first_diagnostic(service)
    diagnostic = service.status.diagnostics.first
    place = diagnostic.location
    "#{diagnostic.header_line} (#{place.buffer.name}:#{place.start_line})"
  end
  private_class_method(:first_diagnostic)
end
