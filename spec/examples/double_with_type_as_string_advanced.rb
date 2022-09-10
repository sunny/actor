# frozen_string_literal: true

class DoubleWithTypeAsStringAdvanced < Actor
  # rubocop:disable Layout/LineLength
  input :value,
        type: {
          is: [Integer, "Float"],
          message: (lambda do |_kind, input_key, _service_name, expected_type_names, actual_type_name|
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
