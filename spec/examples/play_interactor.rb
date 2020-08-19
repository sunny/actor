# frozen_string_literal: true

require_relative './increment_value_with_interactor'

class PlayInteractor < Actor
  input :value, default: 1
  output :value

  play IncrementValueWithInteractor,
       IncrementValueWithInteractor
end
