# frozen_string_literal: true

class SetNameToDowncase < Actor
  input :name
  output :name

  def call
    context.name = name.downcase
  end
end
