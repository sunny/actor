# frozen_string_literal: true

class DoubleWithTypeAsStringAdvanced < Actor
  input :value,
        type: {
          is: [Integer, "Float"],
          message: (-> input_key:, expected_type:, given_type:, ** do
            "Wrong type `#{given_type}` for `#{input_key}`. " \
            "Expected: `#{expected_type}`"
          end),
        }
  output :double

  def call
    self.double = value * 2
  end
end
