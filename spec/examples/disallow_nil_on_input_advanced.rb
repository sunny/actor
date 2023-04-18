# frozen_string_literal: true

class DisallowNilOnInputAdvanced < Actor
  input :name,
        type: String,
        allow_nil: {
          is: false,
          message: (-> input_key:, ** do
            "The value `#{input_key}` cannot be empty"
          end),
        }

  def call; end
end
