# frozen_string_literal: true

class DisallowNilOnOutput < Actor
  output :name, allow_nil: false

  input :test_without_output, default: false

  def call
    self.name = 'Jim' unless test_without_output
  end
end
