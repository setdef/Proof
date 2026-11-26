# frozen_string_literal: true

require_relative("runs_append_contract")
require_relative("runs_durability_contract")
require_relative("runs_find_contract")
require_relative("runs_queue_contract")
require_relative("runs_refusal_contract")

module Proof
  module Testing
    module RunsContract
      include RunsFindContract
      include RunsAppendContract
      include RunsRefusalContract
      include RunsQueueContract
      include RunsDurabilityContract
    end
  end
end
