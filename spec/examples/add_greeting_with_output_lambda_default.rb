# frozen_string_literal: true

class AddGreetingWithOutputLambdaDefault < Actor
  input :name, default: "world", type: String

  output :greeting, type: String
  output :zero_arity_output_default, type: Integer, default: -> { 42 }
  output :one_arity_output_default, type: String, default: -> actor { actor.name + "!" }
  output :nested_lambda_default, type: Proc, default: -> { -> { 43 } }

  def call
    self.greeting = "Hello, #{name}!"
  end
end
