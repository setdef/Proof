# frozen_string_literal: true

# The message of each rule a run keeps, as a test expects it.
module RunRules
  FIRST = "a run's first fact, and only its first, is that it was queued"
  PLACED_ONCE = "a run is placed once"
  STARTS = "a run's command starts once, after the run is placed"
  ENDS = "a run's command ends once, after it starts"
  OUTPUT = "a run's whole output arrives once, after its command ends"
  ARTIFACTS_ONCE = "a run's artifacts are kept or not kept once"
  AFTER_COMMAND = "a run's artifacts are kept, or not kept for a reason other than space, only after its command ends"
  SHORT_OF_SPACE = "a run's artifacts go unkept for space only after it is placed and before its command starts"
  CANCEL_ONCE = "a cancel is asked for once"
  AFTER_FINAL = "a final state is final: only the run's processes ending, once, may follow lost"
  PROCESSES = "a run's processes end as a fact only after the run is lost"
  SUCCEEDS = "a run succeeds only after its command exits with 0, its whole output arrives, and its artifacts are kept"
  FAILS = "a run fails only after its whole output arrives and its command ends with another status than 0 or its " \
    "artifacts aren't kept, or when the server is short of space before its command starts"
  TIMES_OUT = "a run times out only after its command starts"
  OUT_OF_MEMORY = "a run runs out of memory only after its command starts"
  CANCELED = "a run is canceled only after a cancel is asked for"
  LOST = "a run is lost only after it is placed"
  public_constant(*constants)
end
