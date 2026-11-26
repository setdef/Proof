# frozen_string_literal: true

require_relative("test_helper")

# Checks the labels a runner offers and a task asks for.
class LabelSetTest < Minitest::Test
  # A set of the labels with these names.
  def labels(*names)
    Proof::LabelSet.of(*names)
  end

  # Glossary, "label": "the server then places its runs only on runners that
  # have all of them".
  def test_a_runner_with_every_label_of_a_task_offers_them
    assert(labels("desktop", "gpu").offers_every_label_of?(labels("desktop", "gpu")))
  end

  # Glossary, "label": the runner must "have all of them", and a runner with
  # more labels than the task asks for has all of them.
  def test_a_runner_with_more_labels_than_a_task_asks_for_offers_them
    assert(labels("desktop", "gpu", "kvm").offers_every_label_of?(labels("gpu")))
  end

  # Glossary, "label": a runner that lacks one of the task's labels doesn't
  # "have all of them".
  def test_a_runner_missing_one_label_of_a_task_does_not_offer_them
    refute(labels("desktop", "gpu").offers_every_label_of?(labels("gpu", "kvm")))
  end

  # Glossary, "label": a runner with no labels has none of a task's.
  def test_a_runner_with_no_labels_does_not_offer_a_label
    refute(labels.offers_every_label_of?(labels("gpu")))
  end

  # Project file reference, "How values combine": without a project file Proof
  # runs a task "on any operating system with a runner free", so a task that
  # asks for no label needs none.
  def test_a_task_that_asks_for_no_label_is_satisfied_by_any_runner
    assert(labels("gpu").offers_every_label_of?(labels))
    assert(labels.offers_every_label_of?(labels))
  end

  # Project file reference, "Children": `label` takes "One or more labels", and
  # a list of labels names each one once, whatever the order or repeats.
  def test_order_and_repeats_make_no_difference
    assert_equal(labels("gpu", "kvm"), labels("kvm", "gpu", "gpu"))
  end

  # A set of two distinct labels has two labels.
  def test_the_set_holds_each_label_once
    assert_equal(2, labels("kvm", "gpu", "gpu").labels.size)
  end

  # A set built from a list of labels, as the project file reader will.
  def test_a_set_is_built_from_an_array_or_a_set_of_labels
    gpu = Proof::Label.new(name: "gpu")

    assert_equal(labels("gpu"), Proof::LabelSet.new(labels: [gpu]))
    assert_equal(labels("gpu"), Proof::LabelSet.new(labels: Set[gpu]))
  end

  # A set can't be changed after it is built, or two equal sets could differ.
  def test_the_labels_are_frozen_and_a_copy
    given = [Proof::Label.new(name: "gpu")]
    set = Proof::LabelSet.new(labels: given)
    given << Proof::Label.new(name: "kvm")

    assert_equal(1, set.labels.size)
    assert_predicate(set.labels, :frozen?)
  end

  # Glossary, "label": a label is "A name", so a set of labels holds labels.
  def test_anything_but_labels_is_refused
    [["gpu"], [nil], "gpu", nil, 1, { gpu: 1 }].each do |given|
      assert_raises(Proof::InvalidLabelSetError) { Proof::LabelSet.new(labels: given) }
    end
  end

  # A name that can't be a label raises the label's error.
  def test_a_name_that_is_not_a_label_is_refused_where_the_set_is_built_from_names
    assert_raises(Proof::InvalidLabelError) { labels("gpu", "") }
  end

  # The message says what a set holds and what it got.
  def test_the_message_names_the_value
    error = assert_raises(Proof::InvalidLabelSetError) { Proof::LabelSet.new(labels: ["gpu"]) }

    assert_equal('a set of labels holds only labels, not ["gpu"]', error.message)
  end

  # Every error the domain raises is a Proof::Error.
  def test_the_error_is_a_proof_error
    assert_operator(Proof::InvalidLabelSetError, :<, Proof::Error)
  end
end
