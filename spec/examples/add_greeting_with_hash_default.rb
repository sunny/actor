# frozen_string_literal: true

class AddGreetingWithHashDefault < Actor
  input :options, default: {name: "world"}
  output :greeting, type: String

  def call
    self.greeting = "Hello, #{options[:name]}!"
  end
end
