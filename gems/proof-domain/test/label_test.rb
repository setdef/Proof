# frozen_string_literal: true

require_relative("test_helper")

# Checks the names a runner offers beyond its operating system.
class LabelTest < Minitest::Test
  # The start of the message for a name that isn't a label: the rule, with the
  # forms that work. What the name was follows it.
  MESSAGE = "a label is 1 to 63 ASCII letters, digits, hyphens, underscores, or dots, " \
    "beginning and ending with a letter or a digit, with no space, such as " \
    "gpu, kvm, or cuda-12.4, not "
  private_constant(:MESSAGE)

  # Glossary, "label": "A name for something a runner offers beyond its
  # operating system, such as `gpu`, `kvm`, or `desktop`."
  def test_the_labels_the_glossary_names_are_labels
    names = %w[gpu kvm desktop]

    assert_equal(names, names.map { |name| Proof::Label.new(name:).to_s })
  end

  # Project file reference, "Labels": "A label is 1 to 63 characters", so a
  # label has at least one, and a blank name is refused.
  def test_a_blank_name_is_refused
    ["", " ", "\t\n"].each do |name|
      assert_raises(Proof::InvalidLabelError) { Proof::Label.new(name:) }
    end
  end

  # Glossary, "label": a label is "A name"; project file reference, "Children":
  # labels are written as text, such as `gpu`, `kvm`, or `desktop`.
  def test_a_value_that_is_not_text_is_refused
    [nil, :gpu, 1, ["gpu"]].each do |name|
      assert_raises(Proof::InvalidLabelError) { Proof::Label.new(name:) }
    end
  end

  # A byte string that isn't valid text, as a command line can hold, is not a
  # label, and raises the label's error, not Ruby's.
  def test_text_with_invalid_bytes_is_refused
    error = assert_raises(Proof::InvalidLabelError) { Proof::Label.new(name: "gp\xFFu") }

    assert_equal(%(#{MESSAGE}"gp\\xFFu"), error.message)
  end

  # Project file reference, "Labels", table of forms: `gpu`, `kvm`, `desktop`,
  # `GPU`, `cuda-12.4`, `nested_kvm`, `a`, and `"4k"` are valid.
  def test_the_forms_the_reference_lists_as_valid_are_labels
    %w[gpu kvm desktop GPU cuda-12.4 nested_kvm a 4k].each do |name|
      assert_equal(name, Proof::Label.new(name:).name)
    end
  end

  # Project file reference, "Labels": "A label is 1 to 63 characters", so 63
  # characters are a label.
  def test_a_name_of_63_characters_is_a_label
    name = "a#{'-' * 61}z"

    assert_equal(63, name.length)
    assert_equal(name, Proof::Label.new(name:).name)
  end

  # Project file reference, "Labels", table of forms: "A name of 64 or more
  # characters" is "Refused: a label has at most 63."
  def test_a_name_of_64_characters_is_refused
    assert_raises(Proof::InvalidLabelError) { Proof::Label.new(name: "a#{'b' * 63}") }
  end

  # Project file reference, "Labels": a label "has no space", and the table of
  # forms refuses `"gpu "`, `" gpu"`, and `"nvidia gpu"`.
  def test_a_name_with_a_space_is_refused
    ["gpu ", " gpu", "nvidia gpu", "gpu\tkvm"].each do |name|
      assert_raises(Proof::InvalidLabelError, name) { Proof::Label.new(name:) }
    end
  end

  # Project file reference, "Labels": a label begins and ends "with a letter or
  # a digit", and the table of forms refuses `-gpu`, `gpu-`, `.gpu`, and `gpu_`.
  def test_a_name_that_does_not_begin_and_end_with_a_letter_or_a_digit_is_refused
    ["-gpu", "gpu-", ".gpu", "gpu.", "_gpu", "gpu_", "-", "."].each do |name|
      assert_raises(Proof::InvalidLabelError, name) { Proof::Label.new(name:) }
    end
  end

  # Project file reference, "Labels": a label has "ASCII letters, digits, `-`,
  # `_`, and `.`", and the table of forms refuses `gpu!`, `gpu/2`, `gpu:2`, and
  # a name with a letter that isn't ASCII.
  def test_a_name_with_any_other_character_is_refused
    ["gpu!", "gpu/2", "gpu:2", "gpu-ü", "gpü", "gpu*"].each do |name|
      assert_raises(Proof::InvalidLabelError, name) { Proof::Label.new(name:) }
    end
  end

  # Project file reference, "Labels": a label "has no space", so a line break
  # after a valid name isn't part of one, though a pattern anchored with `$`
  # would let it through.
  def test_a_name_with_a_line_break_is_refused
    %W[gpu\n gpu\nkvm \ngpu].each do |name|
      assert_raises(Proof::InvalidLabelError, name) { Proof::Label.new(name:) }
    end
  end

  # The message says the rule, with the forms that work, and what it got.
  def test_the_message_names_the_value
    error = assert_raises(Proof::InvalidLabelError) { Proof::Label.new(name: :gpu) }

    assert_equal("#{MESSAGE}:gpu", error.message)
  end

  # Glossary, "label": the server "places its runs only on runners that have
  # all" of a task's labels, so two labels with one name are one label.
  def test_two_labels_with_one_name_are_equal
    assert_equal(Proof::Label.new(name: "gpu"), Proof::Label.new(name: +"gpu"))
  end

  # Project file reference, "Labels": "Proof compares labels without regard to
  # case, so `GPU` and `gpu` are one label".
  def test_names_that_differ_in_case_are_one_label
    assert_equal(Proof::Label.new(name: "gpu"), Proof::Label.new(name: "GPU"))
    assert_equal(Proof::Label.new(name: "Cuda-12.4"), Proof::Label.new(name: "cUDA-12.4"))
  end

  # Project file reference, "Labels": `GPU` and `gpu` are "one label", so they
  # have one hash code, and a list of them holds one.
  def test_labels_that_differ_in_case_have_one_hash_and_are_eql
    lower = Proof::Label.new(name: "gpu")
    upper = Proof::Label.new(name: "GPU")

    assert_equal(lower.hash, upper.hash)
    assert_operator(lower, :eql?, upper)
    assert_equal(1, [lower, upper].uniq.size)
  end

  # Project file reference, "Labels": "a task that asks for one matches a
  # runner that offers the other", so a set finds a label in either case.
  def test_a_set_finds_a_label_in_either_case
    assert_includes(Set[Proof::Label.new(name: "gpu")], Proof::Label.new(name: "GPU"))
  end

  # Project file reference, "Labels", table of forms: `GPU` is valid as
  # written, so the name keeps the case it was written in.
  def test_the_name_keeps_the_case_it_was_written_in
    label = Proof::Label.new(name: "GPU")

    assert_equal("GPU", label.name)
    assert_equal("GPU", label.to_s)
  end

  # Only case is ignored: labels whose names differ in anything else are two.
  def test_names_that_differ_by_more_than_case_are_two_labels
    refute_equal(Proof::Label.new(name: "gpu"), Proof::Label.new(name: "gpu2"))
    refute_equal(Proof::Label.new(name: "gpu"), Proof::Label.new(name: "kvm"))
  end

  # A label is only ever equal to a label, so a string with its name is not one.
  def test_a_label_is_not_equal_to_its_name_or_to_anything_else
    refute_equal(Proof::Label.new(name: "gpu"), "gpu")
    refute_equal(Proof::Label.new(name: "gpu"), nil)
  end

  # A label built from a string that someone changes later keeps its name.
  def test_the_name_is_frozen_and_is_a_copy
    given = +"gpu"
    label = Proof::Label.new(name: given)
    given << "x"

    assert_equal("gpu", label.name)
    assert_predicate(label.name, :frozen?)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidLabelError, :<, Proof::Error)
  end
end
