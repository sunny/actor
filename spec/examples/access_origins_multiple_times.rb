# frozen_string_literal: true

class AccessOriginsMultipleTimes < Actor
  input :value, type: Integer

  output :value_result, type: Integer
  output :output_with_default, type: Integer, allow_nil: true, default: 42

  play -> actor { actor.value_result = actor.value.succ }
  play -> actor { actor.value_result += 1 }
end
