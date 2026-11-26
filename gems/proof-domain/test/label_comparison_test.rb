# frozen_string_literal: true

require_relative("test_helper")

# Checks when two labels are the same label.
class LabelComparisonTest < Minitest::Test
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
end
