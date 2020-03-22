# frozen_string_literal: true

class SetNameWithInputCondition < Actor
  input :name,
        type: String,
        must: {
          be_lowercase: ->(name) { name =~ /\A[a-z]+\z/ }
        }

  output :name

  def call
    self.name = name.upcase
  end
end
