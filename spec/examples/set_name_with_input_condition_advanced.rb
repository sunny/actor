# frozen_string_literal: true

class SetNameWithInputConditionAdvanced < Actor
  input :name,
        type: String,
        must: {
          be_lowercase: {
            state: -> name { name =~ /\A[a-z]+\z/ },
            message: (lambda do |_input_key, check_name, _value|
              "Failed to apply `#{check_name}`"
            end)
          }
        }

  output :name

  def call
    self.name = name.upcase
  end
end
