# frozen_string_literal: true

class AddGreetingWithDefault < Actor
  input :name, default: 'world', type: String
  output :greeting, type: String

  def call
    self.greeting = "Hello, #{name}!"
  end
end
