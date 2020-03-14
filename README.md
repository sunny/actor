# Actor

Ruby service objects. Lets you move your application logic into small
building blocs to keep your controllers and your models thin.

## Installation

Add these lines to your application's Gemfile:

```rb
# Service objects to keep the business logic
gem 'service_actor', git: 'git@github.com:sunny/actor.git'
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

### Early success

When using `play` you can use `succeed!` so that the following actors will not
be called, but still consider the actor to be successful.

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

### Play conditions

Some actors in a play can be called conditionaly:

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
However there a a few key differences which make `actor` unique:

- Defaults to raising errors on failures. Actor uses `call` and `result` instead of `call!` and `call`. This way, the default is to raise an error and failures are not hidden away.
- Does not [hide errors when an actor fails inside another actor](https://github.com/collectiveidea/interactor/issues/170).
- You can use lambdas inside organizers.
- Requires you to document the arguments with `input` and `output`.
- Type checking of inputs and outputs.
- Inputs and outputs can be required.
- Defaults for inputs.
- Conditions on inputs.
- Shorter fail syntax: `fail!` vs `context.fail!`.
- Trigger early success in organisers with `succeed!`.
- Shorter setup syntax: inherit from `< Actor` vs having to `include Interactor` or `include Interactor::Organizer`.
- Multiple organizers.
- Conditions inside organizers.
- No `before`, `after` and `around` hooks. Prefer simply overriding `call` with `super` which allows wrapping the whole method.
- [Does not rely on `OpenStruct`](https://github.com/collectiveidea/interactor/issues/183)
- Does not print warnings on Ruby 2.7.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then
run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/sunny/actor. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Test project’s codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/sunny/actor/blob/master/CODE_OF_CONDUCT.md).
