# frozen_string_literal: true

class AddGreetingWithDefault < Actor
  input :name, default: 'world'
  output :greeting

  def call
    context.greeting = "Hello, #{name}!"
  end
end
