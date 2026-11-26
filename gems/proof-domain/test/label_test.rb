# frozen_string_literal: true

require_relative("test_helper")

# Checks the names a runner offers beyond its operating system.
class LabelTest < Minitest::Test
  # Glossary, "label": "A name for something a runner offers beyond its
  # operating system, such as `gpu`, `kvm`, or `desktop`."
  def test_the_labels_the_glossary_names_are_labels
    names = %w[gpu kvm desktop]

    assert_equal(names, names.map { |name| Proof::Label.new(name:).to_s })
  end

  # Glossary, "label": a label is "A name", so a blank string names nothing.
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

    assert_equal('a label is a String with something in it, not "gp\xFFu"', error.message)
  end

  # The message says what a label is and what it got.
  def test_the_message_names_the_value
    error = assert_raises(Proof::InvalidLabelError) { Proof::Label.new(name: :gpu) }

    assert_equal("a label is a String with something in it, not :gpu", error.message)
  end

  # Glossary, "label": the server "places its runs only on runners that have
  # all" of a task's labels, so two labels with one name are one label.
  def test_two_labels_with_one_name_are_equal
    assert_equal(Proof::Label.new(name: "gpu"), Proof::Label.new(name: +"gpu"))
  end

  # A name is kept as given: nothing in the docs makes `GPU` the label `gpu`.
  def test_names_that_differ_in_case_are_two_labels
    refute_equal(Proof::Label.new(name: "gpu"), Proof::Label.new(name: "GPU"))
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
