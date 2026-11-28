# frozen_string_literal: true

require_relative("corpus/vector")
require_relative("test_helper")

# Runs every vector of usage 7.4.1's argv conformance corpus against the gem. Each vector is one of three things: one
# the gem agrees with, one whose spec the gem refuses, or a known difference, which test/corpus/known_differences.json
# lists with its reason. A vector that moves from one of the three to another fails, in either direction, so the list
# says what the gem does today.
class UsageCorpusTest < Minitest::Test
  KNOWN = JSON.parse(File.read(File.expand_path("corpus/known_differences.json", __dir__)))
  private_constant(:KNOWN)

  VERDICTS = CorpusVector.all.to_h { |vector| [vector.id.to_s, vector.verdict] }
  private_constant(:VERDICTS)

  # The fixture holds the corpus, which has hundreds of vectors.
  def test_the_corpus_is_there
    assert_operator(VERDICTS.size, :>, 200)
  end

  # A vector that differs is listed with a reason, or the gem is wrong.
  def test_every_vector_agrees_is_refused_or_is_a_known_difference
    unlisted = VERDICTS.select { |id, verdict| verdict == :differs && !known_differences.key?(id) }

    assert_empty(unlisted.keys, "These vectors differ from the corpus. Fix the gem, or list each with its reason.")
  end

  # The list of differences never holds a vector that agrees.
  def test_a_known_difference_still_differs
    stale = known_differences.keys.reject { |id| VERDICTS[id] == :differs }

    assert_empty(stale, "These vectors no longer differ from the corpus. Take them off the list.")
  end

  # The gem refuses each spec the list says it refuses.
  def test_a_refused_spec_is_still_refused
    stale = refused.reject { |id| VERDICTS[id] == :refused }

    assert_empty(stale, "The gem reads these specs now. Take them off the list, and list any that differ.")
  end

  # The gem refuses no spec that the list leaves out.
  def test_every_refused_spec_is_listed
    unlisted = VERDICTS.select { |id, verdict| verdict == :refused && !refused.include?(id) }

    assert_empty(unlisted.keys, "The gem refuses these specs. List them as refused.")
  end

  # A vector renamed or dropped by a later release leaves nothing on the list.
  def test_the_list_names_only_vectors_of_the_corpus
    named = known_differences.keys + refused

    assert_empty(named - VERDICTS.keys)
  end

  # Each reason a difference gives is written down.
  def test_every_known_difference_has_a_reason
    unknown = known_differences.values.uniq - KNOWN["reasons"].keys

    assert_empty(unknown)
  end

  # The vectors the gem answers otherwise than the corpus, each with the key of its reason.
  private def known_differences
    KNOWN["differences"]
  end

  # The ids of the vectors whose spec the gem refuses.
  private def refused
    KNOWN["refused"]["vectors"]
  end
end
