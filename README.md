# Actor

Simple service objects in Ruby. Move your application logic into small building blocs.

## Usage

Actors start with a verb, inherit from `Actor` and implement the `call` method.

```rb
# app/actors/send_notification.rb
class SendNotification < Actor
  def call
    # …
  end
end
```

To use them in your application, use `call`:

```rb
SendNotification.call
```

### Input

Actors can accept arguments with `input`:

```rb
# app/actors/greet_user.rb
class GreetUser < Actor
  input :user

  def call
    puts "Hello #{user.name}!"
  end
end
```

And calling them with:

```rb
GreetUser.call(user: User.first)
```

### Output

They can return arguments with `output`:

```rb
# app/actors/build_greeting.rb
class BuildGreeting < Actor
  output :name

  def call
    context.greeting = "Have a wonderful day!"
  end
end
```


And calling them with:

```rb
result = BuildGreeting.call
result.greeting # => "Have a wonderful day!"
```

### Defaults

Add defaults to your inputs:

```rb
# app/actors/build_greeting.rb
class PrintWelcome < Actor
  input :name
  input :adjective, default: "wonderful"
  input :length_of_time, default: -> { ["day", "week", "month"].sample }

  output :greeting

  def call
    context.greeting = "Hello #{name}! Have a #{adjective} #{length_of_time}!"
  end
end
```

### Result

If you want to test the success of an actor, you can use `fail!` which halts the
actor.

```rb
# app/actors/update_user.rb
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

When using `.call` this will raise an exception.

If you want to test for its success without raising an exception, use `.result`.

For example in a Rails controller you would:

```rb
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    result = UpdateUser.result(user: user, attributes: user_attributes)
    if result.success?
      # …
    else
      # …
    end
  end

  # …
end
```

You can test `#success?` or `#failure?` that way.

### Play

An actor can represent a sequence of actors by using `play`.

```rb
# app/actors/place_order.rb
class PlaceOrder < Actor
  play CreateOrder,
       Pay,
       SendOrderConfirmation,
       NotifyAdmins
end
```

Each actor will be called than will hand over the context to the next actor.

### Rollback

If one of the actors calls `fail!`, all following actors will not be called.
Any previous actor that succeeded will call the `rollback` method.

```rb
class Pay < Actor
  def call
    context.user = User.create!(…)
  end

  def rollback
    context.user.destroy
  end
```

The actor on which you called `fail!` will not be rolled back.

### Lambdas

To do small actions between your actors, you can use lambdas:

```rb
class Pay
  play -> ctx { ctx.payment_method = "stripe" },
       CreatePayment,
       -> ctx { ctx.user_to_notify = ctx.payment.user },
       SendNotification
end
```

### Before, after and around

To do actions before or after actors, you can use lambdas or call `super`:

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

## Heavily influenced by Interactor

This gem loves `interactor`. However here a a few key differences which makes
`actor` unique`.

- Defaults to raising errors on failures.

  Actor encourages you to use `call` and `result` instead of `call!` and `call`. This way, the default is to raise an error and failures are not hidden away.

- Shorter fail syntax.

  Inside an actor you can use `fail!` vs `context.fail!`.

- Shorter setup syntax.

  Inherit from `< Actor` vs having to `include Interactor` and `include Interactor::Organizer`.

- Declare inputs and output with `input` and `output`.

  You are required to document the accepted and returned arguments.

- Defaults for inputs.

  Add defaults with `input :value, default: 0`.

- Type checking of inputs and outputs.

  Optionally check the types of your inputs with `input :value, type: 'Integer'`.

- Methods defined for every input.

  When using `input :name` you can call `name` in your actor instead of `context.name`.

- Allows using lambdas inside an organizer. Can be used to transform the
  context, do quick actions, do before and after cleanup.

  ```rb
  class PlaceComment < Actor
    organize CreateComment,
             -> ctx { ctx.user = ctx.comment.creator },
             UpdateUser
  end
  ```

- No `before_filter` logic.

  Prefer simply overriding `call` with `super` which allows wrapping the whole method.

- Does not hide errors when an actor fails inside another actor.

  https://github.com/collectiveidea/interactor/issues/170
