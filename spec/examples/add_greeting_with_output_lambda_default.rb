# frozen_string_literal: true

class AddGreetingWithOutputLambdaDefault < Actor
  input :name, default: "world", type: String

  output :greeting, type: String
  output :zero_arity_output_default, type: Integer, default: -> { 42 }
  output :one_arity_output_default, type: String, default: -> actor { actor.name + "!" }
  output :nested_lambda_default, type: Proc, default: -> { -> { 43 } }
  output :complex_lambda_default, type: Integer, default: {
    is: -> { 142 },
    message: (lambda do |input_key, actor|
      "Output \"#{input_key}\" is required"
    end),
  }

  def call
    self.greeting = "Hello, #{name}!"
  end
end
