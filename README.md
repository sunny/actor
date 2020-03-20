# Actor

![Tests](https://github.com/sunny/actor/workflows/Tests/badge.svg)

Composable Ruby service objects.

This gems lets you move your application logic into small building blocs to keep
your models and controllers thin.

## Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Defaults](#defaults)
  - [Types](#types)
  - [Requirements](#requirements)
  - [Conditions](#conditions)
  - [Result](#result)
- [Play actors in a sequence](#play-actors-in-a-sequence)
  - [Rollback](#rollback)
  - [Early success](#early-success)
  - [Lambdas](#lambdas)
  - [Before, after and around](#before-after-and-around)
  - [Play conditions](#play-conditions)
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
SendNotification.call
```

### Inputs

Actors can accept arguments with `input`:

```rb
class GreetUser < Actor
  input :user

  def call
    puts "Hello #{user.name}!"
  end
end
```

Inputs can be given as arguments to `call`:

```rb
GreetUser.call(user: User.first)
```

### Outputs

Use `output` to declare what your actor can return. You can then assign every output in
the actor's context.

```rb
class BuildGreeting < Actor
  output :greeting

  def call
    context.greeting = "Have a wonderful day!"
  end
end
```

Calling an actor returns a context:

```rb
result = BuildGreeting.call
result.greeting # => "Have a wonderful day!"
```

### Defaults

Inputs can have defaults:

```rb
class BuildGreeting < Actor
  input :adjective, default: "wonderful"
  input :length_of_time, default: -> { ["day", "week", "month"].sample }

  output :greeting

  def call
    context.greeting = "Have a #{adjective} #{length_of_time}!"
  end
end
```

This lets you call the actor without specifying those keys:

```rb
BuildGreeting.call.greeting # => "Have a wonderful week!"
```

### Types

Inputs can define a type, or an array of possible types it must match:

```rb
class UpdateUser < Actor
  input :user, type: 'User'
  input :age, type: %w[Integer Float]

  # …
end
```

### Requirements

To check that an input must not be `nil`, flag it as required.

```rb
class UpdateUser < Actor
  input :user, required: true

  # …
end
```

### Conditions

You can also add conditions that the inputs must verify, with the name of your
choice under `must`:

```rb
class UpdateAdminUser < Actor
  input :user,
        must: {
          be_an_admin: ->(user) { user.admin? }
        }
end
```

### Result

All actors are successful by default. To stop the execution and mark an actor as
having failed, use `fail!`:

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

This will raise an error in your app.

To test for the success instead of raising, you can use `.result` instead of
`.call`. For example in a Rails controller:

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

## Play actors in a sequence

An actor can be responsible for calling other actors in sequence by using
`play`. Each actor will hand over the same context to the next actor.

```rb
class PlaceOrder < Actor
  play CreateOrder,
       Pay,
       SendOrderConfirmation,
       NotifyAdmins
end
```

### Rollback

When using `play`, when an actor calls `fail!`, the following actors will not be
called.

Instead, all the _previous_ actors that succeeded will have their `rollback`
method triggered.

You can use this to cleanup, for example:

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

### Early success

When using `play` you can use `succeed!` to stop the execution of the following
actors, but still consider the actor to be successful.

### Lambdas

You can use inline actions using lambdas:

```rb
class Pay
  play ->(ctx) { ctx.payment_provider = "stripe" },
       CreatePayment,
       ->(ctx) { ctx.user_to_notify = ctx.payment.user },
       SendNotification
end
```

### Before, after and around

To do actions before or after playing actors, use lambdas or simply override
`call` (or `rollback`) and use `super`. For example:

```rb
class Pay
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
