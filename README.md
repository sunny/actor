# Actor

![Tests](https://github.com/sunny/actor/workflows/Tests/badge.svg)

This Ruby gem lets you move your application logic into into small composable
service objects. It is a lightweight framework that helps you keep your models
and controllers thin.

![Photo of theater seats](https://user-images.githubusercontent.com/132/78340166-e7567000-7595-11ea-97c0-b3e5da2de7a1.png)

## Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Defaults](#defaults)
  - [Conditions](#conditions)
  - [Allow nil](#allow-nil)
  - [Types](#types)
  - [Fail](#fail)
- [Play actors in a sequence](#play-actors-in-a-sequence)
  - [Rollback](#rollback)
  - [Lambdas](#lambdas)
  - [Play conditions](#play-conditions)
- [Testing](#testing)
- [Build your own actor](#build-your-own-actor)
- [Influences](#influences)
- [Thanks](#thanks)
- [Development](#development)
- [Contributing](#contributing)
- [License](#contributing)

## Installation

Add these lines to your application’s Gemfile:

```rb
# Composable service objects
gem "service_actor"
```

When using Rails, you can include the
[service_actor-rails](https://github.com/sunny/actor-rails) gem:

```ruby
# Composable service objects
gem "service_actor-rails"
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

When called, actors return a Result. Reading and writing to this result allows
actors to accept and return multiple arguments. Let’s find out how to do that
and then we’ll see how to chain multiple actors togethor.

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
result = BuildGreeting.call
result.greeting # => "Have a wonderful day!"
```

For each output a method is generated ending with a `?`, which is useful when the output is used for 
conditional control flow, like if-else statements.

```rb
if result.greeting?
  puts "Greetings is a non empty value"
else
  puts "Greetings is empty"
end
```

The generated method will return the truthy or falsey values of variables.

### Defaults

Inputs can be marked as optional by providing a default:

```rb
class BuildGreeting < Actor
  input :name
  input :adjective, default: "wonderful"
  input :length_of_time, default: -> { ["day", "week", "month"].sample }

  output :greeting

  def call
    self.greeting = "Have a #{adjective} #{length_of_time} #{name}!"
  end
end
```

This lets you call the actor without specifying those keys:

```rb
result = BuildGreeting.call(name: "Jim")
result.greeting # => "Have a wonderful week Jim!"
```

If an input does not have a default, it will raise a error:

```rb
result = BuildGreeting.call
=> ServiceActor::ArgumentError: Input name on BuildGreeting is missing.
```

### Conditions

You can ensure an input is included in a collection by using `in`:

```rb
class Pay < Actor
  input :currency, in: %w[EUR USD]

  # …
end
```

This raises an argument error if the input does not match one of the given
values.

You can also add custom conditions with the name of your choice by using `must`:

```rb
class UpdateAdminUser < Actor
  input :user,
        must: {
          be_an_admin: ->(user) { user.admin? }
        }

  # …
end
```

This raises an argument error if the given lambda returns a falsey value.

### Allow nil

By default inputs accept `nil` values. To raise an error instead:

```rb
class UpdateUser < Actor
  input :user, allow_nil: false

  # …
end
```

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

### Fail

To stop the execution and mark an actor as having failed, use `fail!`:

```rb
class UpdateUser
  input :user
  input :attributes

  def call
    user.attributes = attributes

    fail!(error: "Invalid user") unless user.valid?

    # …
  end
end
```

This will raise an error in your app with the given data added to the result.

To test for the success of your actor instead of raising an exception, use
`.result` instead of `.call`. You can then call `success?` or `failure?` on
the result.

For example in a Rails controller:

```rb
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    result = UpdateUser.result(user: user, attributes: user_attributes)
    if result.success?
      redirect_to result.user
    else
      render :new, notice: result.error
    end
  end
end
```

The keys you add to `fail!` will be added to the result, for example you could
do: `fail!(error_type: "validation", error_code: "uv52", …)`.

## Play actors in a sequence

To help you create actors that are small, single-responsibility actions, an
actor can use `play` to call other actors:

```rb
class PlaceOrder < Actor
  play CreateOrder,
       Pay,
       SendOrderConfirmation,
       NotifyAdmins
end
```

This creates a `call` method that will call every actor along the way. Inputs
and outputs will go from one actor to the next, all sharing the same result set
until it is finally returned.

### Rollback

When using `play`, when an actor calls `fail!`, the following actors will not be
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

### Lambdas

You can use inline actions using lambdas. Inside these lambdas you have access to
the shared result:

```rb
class Pay < Actor
  play ->(result) { result.payment_provider = "stripe" },
       CreatePayment,
       ->(result) { result.user_to_notify = result.payment.user },
       SendNotification
end
```

Like in this example, lambdas can be useful for small work or preparing the
result for the next actors. If you want to do more work before, after or around
the whole `play`, you can also override the `call` method. For example:

```rb
class Pay < Actor
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
  play NotifyAdmins, if: ->(result) { result.order.amount > 42 }
end
```

You can use this to trigger an early success.

### Fail on argument error

By default, errors on inputs will raise an error, even when using `.result`
instead of `.call`. If instead you want to mark the actor as failed, you can
catch the exception to treat it as an actor failure:

```rb
class PlaceOrder < Actor
  fail_on ServiceActor::ArgumentError

  input :currency, in: ["EUR", "USD"]

  # …
end
```

## Testing

In your application, add automated testing to your actors as you would do to any
other part of your applications.

You will find that cutting your business logic into single purpose actors will
make it easier for you to test your application.

## Build your own actor

If you application already uses a class called “Actor”, you can build your own
by changing the gem’s require statement:

```rb
gem "service_actor", require: "service_actor/base"
```

And building your own class to inherit from:

```rb
class ApplicationActor
  include ServiceActor::Base
end
```

## Influences

This gem is heavily influenced by
[Interactor](https://github.com/collectiveidea/interactor) ♥.
Some key differences make Actor unique:

- Does not [hide errors when an actor fails inside another
  actor](https://github.com/collectiveidea/interactor/issues/170).
- Requires you to document all arguments with `input` and `output`.
- Defaults to raising errors on failures: actor uses `call` and `result`
  instead of `call!` and `call`. This way, the _default_ is to raise an error
  and failures are not hidden away because you forgot to use `!`.
- Allows defaults, type checking, requirements and conditions on inputs.
- Delegates methods on the context: `foo` vs `context.foo`, `self.foo =` vs
  `context.foo = `, `fail!` vs `context.fail!`.
- Shorter setup syntax: inherit from `< Actor` vs having to `include Interactor`
  and `include Interactor::Organizer`.
- Organizers allow lambdas, being called multiple times, and having conditions.
- Allows early success with conditions inside organizers.
- No `before`, `after` and `around` hooks, prefer using `play` with lambdas or
  overriding `call`.

Actor supports mixing actors & interactors when using `play` for a smooth
migration.

## Thanks

Thank you to @nicoolas25, @AnneSottise & @williampollet for the early thoughts
and feedback on this gem.

Photo by [Lloyd Dirks](https://unsplash.com/photos/4SLz_RCk6kQ).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/rake` to run the tests and linting. You can also run `bin/console` for an
interactive prompt.

To release a new version, update the version number in `version.rb`, and in the
`CHANGELOG.md`. Update the `README.md` if there are missing segments, make sure
tests and linting are pristine by calling `bundle && bin/rake`, then create a
commit for this version.

You can then run `rake release`, which will assign a git tag, push using git,
and push the gem to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome
[on GitHub](https://github.com/sunny/actor).

This project is intended to be a safe, welcoming space for collaboration, and
everyone interacting in the project’s codebase and issue tracker is expected to
adhere to the [Contributor Covenant code of
conduct](https://github.com/sunny/actor/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
