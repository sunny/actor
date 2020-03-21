# frozen_string_literal: true

class DisallowNilOnOutputWithDeprecatedRequired < Actor
  output :name, required: true

  input :test_without_output, default: false

  def call
    self.name = 'Jim' unless test_without_output
  end
end
