# frozen_string_literal: true

class WithUnsetOutput < Actor
  output :value, type: String, allow_nil: true
end
