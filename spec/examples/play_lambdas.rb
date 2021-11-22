# frozen_string_literal: true

require_relative './increment_value'
require_relative './set_name_to_downcase'

class PlayLambdas < Actor
  output :name, type: String

  play ->(result) { result.value = 3 },
       IncrementValue,
       ->(result) { result.name = "Jim number #{result.value}" },
       ->(_) { { name: 'Does nothing' } },
       SetNameToDowncase
end
