# frozen_string_literal: true

module Proof
  module Testing
    QUICK_TAGS = TagMaker.new(cost: SlowTag::Cost.new(n: 2, r: 1, p: 1, length: SlowTag::COST.length))
    public_constant(:QUICK_TAGS)
  end
end
