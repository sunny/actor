# frozen_string_literal: true

class AddHashToContext < Actor
  output :stuff, type: 'Hash'

  def call
    context.stuff = { name: 'Jim' }
  end
end
