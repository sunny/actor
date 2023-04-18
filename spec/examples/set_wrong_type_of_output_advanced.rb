# frozen_string_literal: true

class SetWrongTypeOfOutputAdvanced < Actor
  output :name,
         type: {
           is: String,
           message: (-> input_key:, expected_type:, given_type:, ** do
             "Wrong type `#{given_type}` for `#{input_key}`. " \
             "Expected: `#{expected_type}`"
           end),
         }
  def call
    self.name = 42
  end
end
