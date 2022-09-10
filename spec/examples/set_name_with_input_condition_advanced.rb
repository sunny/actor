# frozen_string_literal: true

class SetNameWithInputConditionAdvanced < Actor
  input :name,
        type: String,
        must: {
          be_lowercase: {
            is: -> name { name =~ /\A[a-z]+\z/ },
            message: (lambda do |check_name:, **|
              "Failed to apply `#{check_name}`"
            end)
          }
        }

  output :name

  def call
    self.name = name.upcase
  end
end
