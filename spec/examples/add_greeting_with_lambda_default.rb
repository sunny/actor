# frozen_string_literal: true

class AddGreetingWithLambdaDefault < Actor
  input :name, default: -> { 'world' }

  def call
    context.greeting = "Hello, #{name}!"
  end
end
