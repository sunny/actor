# frozen_string_literal: true

class SetNameToDowncase < Actor
  input :name, type: 'String'
  output :name, type: 'String'

  def call
    context.name = name.downcase
  end
end
