# frozen_string_literal: true

class AddGreetingWithDefault < Actor
  input :name, default: 'world', type: 'String'
  output :greeting, type: 'String'

  def call
    context.greeting = "Hello, #{name}!"
  end
end
