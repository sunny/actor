# frozen_string_literal: true

require_relative './increment_value'
require_relative './do_nothing'
require_relative './add_name_to_context'
require_relative './set_name_to_downcase'
require_relative './increment_value'

class PlayActors < Actor
  input :value, type: 'Integer'
  output :value, type: 'Integer'
  output :name, type: 'String'

  play IncrementValue,
       DoNothing,
       AddNameToContext,
       SetNameToDowncase,
       IncrementValue
end
