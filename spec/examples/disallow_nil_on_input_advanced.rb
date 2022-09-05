# frozen_string_literal: true

class DisallowNilOnInputAdvanced < Actor
  input :name,
        type: String,
        allow_nil: false,
        allow_nil_message: (lambda do |_origin, input_key, _service_name|
          "The value `#{input_key}` cannot be empty"
        end)

  def call; end
end
