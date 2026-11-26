# frozen_string_literal: true

require_relative("test_helper")

# Checks adding the labels of one source to those of another.
class LabelSetUnionTest < Minitest::Test
  # Project file reference, "How values combine": "`label` ... add: a task's
  # entries add to those in `defaults`", so the union has the labels of both.
  def test_the_union_has_the_labels_of_both_sets
    union = Proof::LabelSet.of("desktop") | Proof::LabelSet.of("gpu")

    assert_equal(Proof::LabelSet.of("gpu", "desktop"), union)
  end

  # Project file reference, "Labels": "Proof compares labels without regard to
  # case", so a label in both sets, in two cases, is one label.
  def test_a_label_in_both_sets_counts_once_whatever_its_case
    assert_equal(1, (Proof::LabelSet.of("GPU") | Proof::LabelSet.of("gpu")).labels.size)
  end

  # Adding the labels of nothing changes nothing.
  def test_the_union_with_an_empty_set_is_the_same_set
    assert_equal(Proof::LabelSet.of("gpu"), Proof::LabelSet.of("gpu") | Proof::LabelSet.of)
  end

  # A union is a new set, and the two it came from stay as they were.
  def test_the_union_leaves_both_sets_as_they_were
    left = Proof::LabelSet.of("desktop")
    union = left | Proof::LabelSet.of("gpu")

    assert_equal([Proof::LabelSet.of("desktop"), 2], [left, union.labels.size])
  end
end
