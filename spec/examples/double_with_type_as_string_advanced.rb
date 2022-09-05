# frozen_string_literal: true

class DoubleWithTypeAsStringAdvanced < Actor
  # rubocop:disable Layout/LineLength
  input :value,
        type: {
          class_name: [Integer, "Float"],
          message: (lambda do |_kind, input_key, _service_name, actual_type_name, expected_type_names|
            "Wrong type `#{actual_type_name}` for `#{input_key}`. " \
            "Expected: `#{expected_type_names}`"
          end)
        }
  # rubocop:enable Layout/LineLength

  output :double

  def call
    self.double = value * 2
  end
end
