# frozen_string_literal: true

class SetWrongRequiredOutput < Actor
  output :name, allow_nil: false

  def call
    # Expected to fail since it is required and we don’t output `name`.
  end
end
