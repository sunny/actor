# frozen_string_literal: true

class DoubleWithTypeAsStringAdvanced < Actor
  input :value,
        type: {
          class_name: [Integer, "Float"],
          message: (lambda do |_kind, input_key, _service_name, expected_type_names, actual_type_name|
            "Wrong type `#{actual_type_name}` for `#{input_key}`. " \
            "Expected: `#{expected_type_names}`"
          end)
        }

  output :double

  def call
    self.double = value * 2
  end
end
