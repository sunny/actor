# frozen_string_literal: true

class CheckNilAdvancedNoMessage < Actor
  input :name,
        allow_nil: {
          is: false
        }
end
