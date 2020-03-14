# Actor

Simple service objects in Ruby. Move your application logic into small building blocs to keep your controllers and your models thin.

## Install

This has not been released yet and is not ready for use in your applications.

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

Use `.call` to use them in your application:

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

And receive them as arguments to `call`:

```rb
GreetUser.call(user: User.first)
```

### Outputs

Use `output` to declare what your actor can return, then assign them to your
context.

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
class PrintWelcome < Actor
  input :user
  input :adjective, default: "wonderful"
  input :length_of_time, default: -> { ["day", "week", "month"].sample }

  output :greeting

  def call
    context.greeting = "Hello #{name}! Have a #{adjective} #{length_of_time}!"
  end
end
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

### Conditions

If types don't cut it, you can add small conditions with the name of your choice
under `must`:

```rb
class UpdateAdminUser < Actor
  input :user,
        must: {
          be_an_admin: ->(user) { user.admin? }
        }
end
```

### Result

All actors are successful by default. To stop its execution and mark is as
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

You can then test for the success by calling your actor with `.result` instead
of `.call`. This will let you test for `success?` or `failure?` on the context
instead of raising an exception.

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

### Play

An actor can call actors in sequence by using `play`. Each actor will hand over
the context to the next actor.

```rb
# app/actors/place_order.rb
class PlaceOrder < Actor
  play CreateOrder,
       Pay,
       SendOrderConfirmation,
       NotifyAdmins
end
```


### Rollback

When using `play`, if one of the actors calls `fail!`, the following actors will
not be called.

Also, any _previous_ actor that succeeded will call the `rollback` method, if
you defined one.

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

### Lambdas

You can call inline actions using lambdas:

```rb
class Pay
  play ->(ctx) { ctx.payment_provider = "stripe" },
       CreatePayment,
       ->(ctx) { ctx.user_to_notify = ctx.payment.user },
       SendNotification
end
```

### Before, after and around

To do actions before or after actors, use lambdas or simply override `call` and
use `super`. For example:

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

## Influences

This gem is heavily influenced by
[Interactor](https://github.com/collectiveidea/interactor) ♥♥♥.
However there a a few key differences which make `actor` unique:

- Defaults to raising errors on failures.

  Actor encourages you to use `call` and `result` instead of `call!` and `call`. This way, the default is to raise an error and failures are not hidden away.

- Methods defined for every input.

  When using `input :name` you can call `name` in your actor instead of `context.name`.

- No `before`, `after` and `around` hooks.

  Prefer simply overriding `call` with `super` which allows wrapping the whole method.

- Does not [hide errors when an actor fails inside another actor](https://github.com/collectiveidea/interactor/issues/170).
- You can use lambdas inside organizers.
- Requires you to document the arguments with `input` and `output`.
- Type checking of inputs and outputs.
- Required inputs and outputs.
- Defaults for inputs.
- Conditions on inputs.
- Shorter fail syntax: `fail!` vs `context.fail!`.
- Shorter setup syntax: inherit from `< Actor` vs having to `include Interactor` or `include Interactor::Organizer`.
- [Does not rely on `OpenStruct`](https://github.com/collectiveidea/interactor/issues/183)
- Does not print warnings on Ruby 2.7.
