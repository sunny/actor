# ServiceActor

This Ruby gem lets you move your application logic into small composable
service objects. It is a lightweight framework that helps you keep your models
and controllers thin.

![Photo of theater seats](https://user-images.githubusercontent.com/132/78340166-e7567000-7595-11ea-97c0-b3e5da2de7a1.png)

## Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Fail](#fail)
- [Play actors in a sequence](#play-actors-in-a-sequence)
  - [Rollback](#rollback)
  - [Inline actors](#inline-actors)
  - [Play conditions](#play-conditions)
  - [Input aliases](#input-aliases)
- [Input options](#input-options)
  - [Defaults](#defaults)
  - [Allow nil](#allow-nil)
  - [Conditions](#conditions)
  - [Types](#types)
  - [Custom input errors](#custom-input-errors)
  - [Custom type validations](#custom-type-validations)
- [Testing](#testing)
- [FAQ](#faq)
- [Thanks](#thanks)
- [Contributing](#contributing)
- [License](#contributing)

## Installation

Add the gem to your application’s Gemfile by executing:

```sh
bundle add service_actor
```

### Extensions

For **Rails generators**, you can use the
[service_actor-rails](https://github.com/sunny/actor-rails) gem:

```sh
bundle add service_actor-rails
```

For **TTY prompts**, you can use the
[service_actor-promptable](https://github.com/pboling/service_actor-promptable) gem:

```sh
bundle add service_actor-promptable
```

## Usage

Actors are single-purpose actions in your application that represent your
business logic. They start with a verb, inherit from `Actor` and implement a
`call` method.

```rb
# app/actors/send_notification.rb
class SendNotification < Actor
  def call
    # …
  end
end
```

Trigger them in your application with `.call`:

```rb
SendNotification.call # => <ServiceActor::Result…>
```

When called, an actor returns a result. Reading and writing to this result allows
actors to accept and return multiple arguments. Let’s find out how to do that
and then we’ll see how to
[chain multiple actors together](#play-actors-in-a-sequence).

### Inputs

To accept arguments, use `input` to create a method named after this input:

```rb
class GreetUser < Actor
  input :user

  def call
    puts "Hello #{user.name}!"
  end
end
```

You can now call your actor by providing the correct arguments:

```rb
GreetUser.call(user: User.first)
```

### Outputs

An actor can return multiple arguments. Declare them using `output`, which adds
a setter method to let you modify the result from your actor:

```rb
class BuildGreeting < Actor
  output :greeting

  def call
    self.greeting = "Have a wonderful day!"
  end
end
```

The result you get from calling an actor will include the outputs you set:

```rb
actor = BuildGreeting.call
actor.greeting # => "Have a wonderful day!"
actor.greeting? # => true
```

If you only have one value you want from an actor, you can skip defining an
output by making it the return value of `.call()` and calling your actor with
`.value()`:

```rb
class BuildGreeting < Actor
  input :name

  def call
    "Have a wonderful day, #{name}!"
  end
end

BuildGreeting.value(name: "Fred") # => "Have a wonderful day, Fred!"
```

### Fail

To stop the execution and mark an actor as having failed, use `fail!`:

```rb
class UpdateUser < Actor
  input :user
  input :attributes

  def call
    user.attributes = attributes

    fail!(error: "Invalid user") unless user.valid?

    # …
  end
end
```

This will raise an error in your application with the given data added to the
result.

To test for the success of your actor instead of raising an exception, use
`.result` instead of `.call`. You can then call `success?` or `failure?` on
the result.

For example in a Rails controller:

```rb
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    actor = UpdateUser.result(user: user, attributes: user_attributes)
    if actor.success?
      redirect_to actor.user
    else
      render :new, notice: actor.error
    end
  end
end
```

> [!WARNING]
> If you specify the type option for output fields, it will not be enforced for failed actors.
> As a result, their output might not match the specified type.

## Play actors in a sequence

To help you create actors that are small, single-responsibility actions, an
actor can use `play` to call other actors:

```rb
class PlaceOrder < Actor
  play CreateOrder,
       PayOrder,
       SendOrderConfirmation,
       NotifyAdmins
end
```

Calling this actor will now call every actor along the way. Inputs and outputs
will go from one actor to the next, all sharing the same result set until it is
finally returned.

If you use `.value()` to call this actor, it will give the return value of
the final actor in the play chain.

### Rollback

When using `play`, if an actor calls `fail!`, the following actors will not be
called.

Instead, all the actors that succeeded will have their `rollback` method called
in reverse order. This allows actors a chance to cleanup, for example:

```rb
class CreateOrder < Actor
  output :order

  def call
    self.order = Order.create!(…)
  end

  def rollback
    order.destroy
  end
end
```

Rollback is only called on the _previous_ actors in `play` and is not called on
the failing actor itself. Actors should be kept to a single purpose and not have
anything to clean up if they call `fail!`.

### Inline actors

For small work or preparing the result set for the next actors, you can create
inline actors by using lambdas. Each lambda has access to the shared result. For
example:

```rb
class PayOrder < Actor
  input :order

  play -> actor { actor.order.currency ||= "EUR" },
       CreatePayment,
       UpdateOrderBalance,
       -> actor { Logger.info("Order #{actor.order.id} paid") }
end
```

You can also call instance methods. For example:

```rb
class PayOrder < Actor
  input :order

  play :assign_default_currency,
       CreatePayment,
       UpdateOrderBalance,
       :log_payment

  private

  def assign_default_currency
    order.currency ||= "EUR"
  end

  def log_payment
    Logger.info("Order #{order.id} paid")
  end
end
```

If you want to do work around the whole actor, you can also override the `call`
method. For example:

```rb
class PayOrder < Actor
  # …

  def call
    Time.with_timezone("Paris") do
      super
    end
  end
end
```

### Play conditions

Actors in a play can be called conditionally:

```rb
class PlaceOrder < Actor
  play CreateOrder,
       Pay
  play NotifyAdmins, if: -> actor { actor.order.amount > 42 }
  play CreatePayment, unless: -> actor { actor.order.currency == "USD" }
end
```

### Input aliases

You can use `alias_input` to transform the output of an actor into the input of
the next actors.

```rb
class PlaceComment < Actor
  play CreateComment,
       NotifyCommentFollowers,
       alias_input(commenter: :user),
       UpdateUserStats
end
```

## Input options

### Defaults

Inputs can be optional by providing a `default` value in a lambda.

```rb
class BuildGreeting < Actor
  input :name
  input :adjective, default: -> { "wonderful" }
  input :length_of_time, default: -> { ["day", "week", "month"].sample }
  input :article,
        default: -> actor { actor.adjective.match?(/^[aeiou]/) ? "an" : "a" }

  output :greeting

  def call
    self.greeting = "Have #{article} #{adjective} #{length_of_time}, #{name}!"
  end
end

actor = BuildGreeting.call(name: "Jim")
actor.greeting # => "Have a wonderful week, Jim!"

actor = BuildGreeting.call(name: "Siobhan", adjective: "elegant")
actor.greeting # => "Have an elegant week, Siobhan!"
```

While lambdas are the preferred way to specify defaults, you can also provide
a default value without using lambdas by using an immutable object.

```rb
# frozen_string_literal: true

class ExampleActor < Actor
  input :options, default: {
    names: {male: "Iaroslav", female: "Anna"}.freeze,
    country_codes: %w[gb ru].freeze
  }.freeze
end
```

Note that default values might be mutated if the values returned by the lambda
are references to mutable objects, e.g.

```rb
class ExampleActor < Actor
  input :options, default: -> { Registry::DEFAULT_OPTIONS } # `Registry::DEFAULT_OPTIONS` is not frozen

  def call
    options[:names] = nil
  end
end
```

### Allow nil

By default inputs accept `nil` values. To raise an error instead:

```rb
class UpdateUser < Actor
  input :user, allow_nil: false

  # …
end
```

### Conditions

You can ensure an input is included in a collection by using `inclusion`:

```rb
class Pay < Actor
  input :currency, inclusion: %w[EUR USD]

  # …
end
```

This raises an argument error if the input does not match one of the given
values.

Declare custom conditions with the name of your choice by using `must`:

```rb
class UpdateAdminUser < Actor
  input :user,
        must: {
          be_an_admin: -> user { user.admin? }
        }

  # …
end
```

This will raise an argument error if any of the given lambdas returns a falsey
value.

### Types

Sometimes it can help to have a quick way of making sure we didn’t mess up our
inputs.

For that you can use the `type` option and giving a class or an array
of possible classes. If the input or output doesn’t match these types, an
error is raised.

```rb
class UpdateUser < Actor
  input :user, type: User
  input :age, type: [Integer, Float]

  # …
end
```

You may also use strings instead of constants, such as `type: "User"`.

When using a type condition, `allow_nil` defaults to `false`.

### Custom input errors

Use a `Hash` with `is:` and `message:` keys to prepare custom
error messages on inputs. For example:

```rb
class UpdateAdminUser < Actor
  input :user,
        must: {
          be_an_admin: {
            is: -> user { user.admin? },
            message: "The user is not an administrator"
          }
        }

  # ...
end
```

You can also use incoming arguments when shaping your error text:

```rb
class UpdateUser < Actor
  input :user,
        allow_nil: {
          is: false,
          message: (lambda do |input_key:, **|
            "The value \"#{input_key}\" cannot be empty"
          end)
        }

  # ...
end
```

<details>
  <summary>See examples of custom messages on all input arguments</summary>

  #### Inclusion

  ```ruby
  class Pay < Actor
    input :provider,
          inclusion: {
            in: ["MANGOPAY", "PayPal", "Stripe"],
            message: (lambda do |value:, **|
              "Payment system \"#{value}\" is not supported"
            end)
          }
  end
  ```

  #### Must

  ```ruby
  class Pay < Actor
    input :provider,
          must: {
            exist: {
              is: -> provider { PROVIDERS.include?(provider) },
              message: (lambda do |value:, **|
                "The specified provider \"#{value}\" was not found."
              end)
            }
          }
  end
  ```

  #### Type

  ```ruby
  class ReduceOrderAmount < Actor
    input :bonus_applied,
          type: {
            is: [TrueClass, FalseClass],
            message: (lambda do |input_key:, expected_type:, given_type:, **|
              "Wrong type \"#{given_type}\" for \"#{input_key}\". " \
                "Expected: \"#{expected_type}\""
            end)
          }
  end
  ```

  #### Allow nil

  ```ruby
  class CreateUser < Actor
    input :name,
          allow_nil: {
            is: false,
            message: (lambda do |input_key:, **|
              "The value \"#{input_key}\" cannot be empty"
            end)
          }
  end
  ```

</details>

### Custom type validations

This gem provides a minimal API for checking the types of `input` and `output` values:

- A direct class match: `input :age, type: Integer`
- A disjunction of classes: `output :height, type: [Integer, Float]`

More complex type checks are outside the scope of this gem. However, type checking is performed using Ruby’s `===` method.
This means you can define a custom class with a `===` method to implement your own type logic.

For example, to define a “positive integer” type, you can create a custom class:

```ruby
class PositiveInteger
  class << self
    def ===(value)
      value.is_a?(Integer) && value.positive?
    end
  end
end
```

Then you can use it in an actor:

```ruby
class AgeActor < Actor
  input :age, type: PositiveInteger
end

AgeActor.call(age: 25) # => #<ServiceActor::Result {age: 25}>
AgeActor.call(age: -42) # ServiceActor::ArgumentError: The "age" input on "AgeActor" must be of type "PositiveInteger" but was "Integer" (ServiceActor::ArgumentError)
```

This approach also allows you to define adapters for third-party validation gems, providing the flexibility to integrate custom type checks.

See [more examples](./docs/examples/custom_types).

## Testing

In your application, add automated testing to your actors as you would do to any
other part of your applications.

You will find that cutting your business logic into single purpose actors will
make it easier for you to test your application.

## FAQ

Howtos and frequently asked questions can be found on the
[wiki](https://github.com/sunny/actor/wiki).

## Thanks

This gem is influenced by (and compatible with)
[Interactor](https://github.com/sunny/actor/wiki/Interactor).

Thank you to the wonderful
[contributors](https://github.com/sunny/actor/graphs/contributors).

Thank you to @nicoolas25, @AnneSottise & @williampollet for the early thoughts
and feedback on this gem.

Photo by [Lloyd Dirks](https://unsplash.com/photos/4SLz_RCk6kQ).

## Contributing

See
[CONTRIBUTING.md](https://github.com/sunny/actor/blob/main/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://choosealicense.com/licenses/mit/).
