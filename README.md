# Actor

![Tests](https://github.com/sunny/actor/workflows/Tests/badge.svg)

This Ruby gem lets you move your application logic into into small composable
service objects. It is a lightweight framework that helps you keep your models
and controllers thin.

## Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Defaults](#defaults)
  - [Types](#types)
  - [Allow nil](#allow-nil)
  - [Conditions](#conditions)
  - [Result](#result)
- [Play actors in a sequence](#play-actors-in-a-sequence)
  - [Rollback](#rollback)
  - [Early success](#early-success)
  - [Lambdas](#lambdas)
  - [Play conditions](#play-conditions)
- [Testing](#testing)
- [Influences](#influences)
- [Development](#development)
- [Contributing](#contributing)
- [License](#contributing)

## Installation

Add these lines to your application's Gemfile:

```rb
# Composable service objects
gem 'service_actor'
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
SendNotification.call # => <Actor::Context …>
```

Actors can accept and return multiple arguments. To do so, they read and write
to their `context` using inputs and outputs. Let's find out how to do that.

### Inputs

To accept arguments, use `input`:

```rb
class GreetUser < Actor
  input :user

  def call
    puts "Hello #{user.name}!"
  end
end
```

When executing your actor, `user` is a shortcut to `context.user`.

You can now call your actor by providing the correct context:

```rb
GreetUser.call(user: User.first)
```

### Outputs

An actor can return multiple arguments. Declare them using `output` to help
clarify what this service does.

Then, modify the context from inside your `call` method:

```rb
class BuildGreeting < Actor
  output :greeting

  def call
    context.greeting = 'Have a wonderful day!'
  end
end
```

Calling an actor returns the context with the outputs you defined:

```rb
result = BuildGreeting.call
result.greeting # => "Have a wonderful day!"
```

### Defaults

Inputs can be marked as optional by providing a default:

```rb
class BuildGreeting < Actor
  input :name
  input :adjective, default: 'wonderful'
  input :length_of_time, default: -> { ['day', 'week', 'month'].sample }

  output :greeting

  def call
    context.greeting = "Have a #{adjective} #{length_of_time} #{name}!"
  end
end
```

This lets you call the actor without specifying those keys:

```rb
result = BuildGreeting.call(name: 'Jim')
result.greeting # => "Have a wonderful week Jim!"
```

If an input does not have a default, it will raise a error:

```rb
result = BuildGreeting.call
=> ArgumentError: Input name on BuildGreeting is missing.
```

### Conditions

You can add simple conditions that the inputs must verify, with the name of your
choice under `must`:

```rb
class UpdateAdminUser < Actor
  input :user,
        must: {
          be_an_admin: ->(user) { user.admin? }
        }

  # …
end
```

In case the input does not match, it will raise an argument error.

### Types

Sometimes it can help to have a quick way of making sure we didn't mess up our
inputs. For that you can use `type` with the name of a class or an array of
possible classes it must be an instance of.

```rb
class UpdateUser < Actor
  input :user, type: 'User'
  input :age, type: %w[Integer Float]

  # …
end
```

An exception will be raised if the type doesn't match.

### Allow nil

By default inputs allow the values to be `nil`. To raise an error on `nil`,
flag it as required.

```rb
class UpdateUser < Actor
  input :user, required: true

  # …
end
```

### Result

All actors return a successful `context` by default. To stop the execution and
mark an actor as having failed, use `fail!`:

```rb
class UpdateUser
  input :user
  input :attributes

  def call
    user.attributes = attributes

    fail!(error: 'Invalid user') unless user.valid?

    # …
  end
end
```

This will stop the execution of your actor and raise an error in your app with
the given data added to the context.

To test for the success of your actor, use `.result` instead of `.call`. It will
allow you to return the context without raising an error in case of failure.

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

Any keys you add to `fail!` will be added to the context, for example you could
do: `fail!(error_type: "validation", error_code: "uv52", …)`.

## Play actors in a sequence

You should aim for your actors to be small, single-responsibility actions in
your application.

To help you do that, an actor can use `play` for calling other actors:

```rb
class PlaceOrder < Actor
  play CreateOrder,
       Pay,
       SendOrderConfirmation,
       NotifyAdmins
end
```

This creates a `call` method where each actor will be called with the same
context. Therefore, outputs from one actor can be used as inputs for the next,
and each actor along the way can help shape the final context you application needs.

### Rollback

When using `play`, when an actor calls `fail!`, the following actors will not be
called.

Instead, all the actors that succeeded will have their `rollback` method called
in reverse order. This allows actors a chance to cleanup, for example:

```rb
class CreateOrder < Actor
  def call
    context.order = Order.create!(…)
  end

  def rollback
    context.order.destroy
  end
end
```

Rollback is only called on the _previous_ actors in `play` and is not called on
the failing actor itself. Actors should be kept to a single purpose and not have
anything to clean up if they call `fail!`.

### Early success

When using `play` you can use `succeed!` to stop the execution of the following
actors, but still consider the actor to be successful.

### Lambdas

You can use inline actions using lambdas, which can be useful for preparing the
context for the next actors:

```rb
class Pay < Actor
  play ->(ctx) { ctx.payment_provider = "stripe" },
       CreatePayment,
       ->(ctx) { ctx.user_to_notify = ctx.payment.user },
       SendNotification
end
```

If you want to do more work before, or after the whole `play`, you can override
`call` and use `super`. For example:

```rb
class Pay < Actor
  # …

  def call
    Time.with_timezone('Paris') do
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
  play NotifyAdmins, if: ->(ctx) { ctx.order.amount > 42 }
end
```

## Testing

In your application, add automated testing to your actors as you would do to any
other part of your applications.

You will find that cutting your business logic into single purpose actors makes
your application much simpler to test.

## Influences

This gem is heavily influenced by
[Interactor](https://github.com/collectiveidea/interactor) ♥.
However there are a few key differences which make `actor` unique:

- Does not [hide errors when an actor fails inside another
  actor](https://github.com/collectiveidea/interactor/issues/170).
- Requires you to document all arguments with `input` and `output`.
- Defaults to raising errors on failures: actor uses `call` and `result`
  instead of `call!` and `call`. This way, the _default_ is to raise an error
  and failures are not hidden away because you forgot to use `!`.
- Allows defaults, type checking, requirements and conditions on inputs.
- Delegates methods on the context: `foo` vs `context.foo` (as well as `fail!`
  vs `context.fail!`).
- Shorter setup syntax: inherit from `< Actor` vs having to `include Interactor`
  and `include Interactor::Organizer`.
- Organizers allow lambdas, being called multiple times and with conditions.
- Allows triggering an early success with `succeed!`.
- No `before`, `after` and `around` hooks, prefer using `play` with lambdas or
  calling `super`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run the tests and linting. You can also run `bin/console` for an
interactive prompt.

To release a new version, update the version number in `version.rb`, and then
run `rake release`, which will create a git tag for the version, push git
commits and tags, and push the gem to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome
[on GitHub](https://github.com/sunny/actor).

This project is intended to be a safe, welcoming space for collaboration, and
everyone interacting in the project’s codebase and issue tracker is expected to
adhere to the [Contributor Covenant code of
conduct](https://github.com/sunny/actor/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
