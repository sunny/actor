# frozen_string_literal: true

class SetWrongTypeOfOutputAdvanced < Actor
  # rubocop:disable Layout/LineLength
  output :name,
         type: {
           is: String,
           message: (lambda do |input_key:, expected_type_names:, actual_type_name:, **|
             "Wrong type `#{actual_type_name}` for `#{input_key}`. " \
             "Expected: `#{expected_type_names}`"
           end)
         }
  # rubocop:enable Layout/LineLength

  def call
    self.name = 42
  end
end
