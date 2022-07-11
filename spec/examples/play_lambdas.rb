# frozen_string_literal: true

require_relative "./increment_value"
require_relative "./set_name_to_downcase"

class PlayLambdas < Actor
  output :name, type: String

  play -> actor { actor.value = 3 },
       IncrementValue,
       -> actor { actor.name = "Jim number #{actor.value}" },
       -> _ { { name: "Does nothing" } },
       SetNameToDowncase
end
