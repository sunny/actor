# Changelog

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## unreleased

Fixes:
- Add `#hash` and `#instance_of?` to `ServiceActor::Result` (#168)

## v3.9.3

Fixes:
- Fail actor when playing a failing Interactor (#164)
- Accept a Hash with String keys as arguments (#170)

## v3.9.2

Fixes:
- Add `#nil?`, `#methods`, `#blank?` and `#private_methods`to `ServiceActor::Result` (#146, #162)
- Accept inputs called `error` (#146)

## v3.9.1

Fix:
- Fix repeated `play` calls when the element is an actor that returns nil (#155)

## v3.9.0

Feature:
- Add support for `value()` method on actors (#152)

Fix:
- Allow setting `failure?: true` on a result as well as `failure: true` (#153)

## v3.8.1

Fix:
- Add more introspection methods to `ServiceActor::Result` to prevent exceptions
  on apps that depended on them (#148)

## v3.8.0

Features:
- Add pattern matching support for `ServiceActor::Result` (#134)

Fixes:
- Allow using a Hash as `default:` (#119)
- Add default message to missing `message` key on advanced `input` or `output`
  checks (#117)
- Deprecate invoking undefined methods on `ServiceActor::Result` (#129)
- Ensure `input`, `output` and `alias_input` names do not collide with
  `ServiceActor::Result` instance methods (#138)
- Refactor `ServiceActor::Result` to get rid of `OpenStruct` inheritance
  (#127)
- Ensure provided `failure_class` and `argument_error_class` values
  are subclasses of `Exception` (#132)
- Ensure provided `fail_on` arguments are subclasses of `Exception` (#136)
- Skip `default` check for actor outputs (#135)
- Remove unused `DefaultCheck` (#144)

Dependencies:
- Drop support for Ruby before 2.7 (#126)

## v3.7.0

Features:
- `default` lambdas optionally accept a `context` with other attributes (#112)
- Handle `unless:` condition on a `play` (#116)

## v3.6.1

Fixes:
- Catch errors in the code inside the `must` check (#105)
- Allow calling `#fail!` on a Result (#107)

## v3.6.0

Features:
- When raising input errors, raise them in the order that they are defined (#97)

## v3.5.0

Features:
- Add `alias_input` method to aliases inputs and outputs (#96)

## v3.4.1

Fixes:
- Fix exception on load when requiring `service_actor/base` directly (#89)

## v3.4.0

Features:
- Accept custom error messages on `input` and `output` (#82)
- Customize the exception class raised on inputs (#86)
- Rename the `in:` option to `inclusion:` (#84)

Fixes:
- The “Input … must be included in …” error message is now correctly raised as a
  `ServiceActor::ArgumentError` instead of an `ArgumentError` (#83)

## v3.3.0

Features:
- Allow using actors as defaults, which can help with dependency injection (#74)

Fixes:
- The `if:` condition on a `play` is called only once, instead of once per
  actor (#73)

## v3.2.0

Features:
- The `play` method accepts instance methods as symbols (#72)
- Add `*?` methods to results for boolean comparison (#59)

## v3.1.3

Fixes:
- The `play` method recognizes as actors anything that inherits from
  `ServiceActor::Core` instead of just `Actor` (#46)
- The `play` method does not try to merge results of lambdas returning hashes
  (#56)
- Remove warning when redefine an input (#52)
- Remove warning when calling `#rollback` (#54)

## v3.1.2

Fixes:
- The `in:` option supports the `default:` keyword as well (#44)

## v3.1.1

Fixes:
- Ruby 2.4 and 3 support (#34)

## v3.1.0

Added:
- Add `fail_on` to catch argument errors and turn them into actor failures (#30)

Fixes:
- Harmonize error messages by removing trailing dots (#31)

## v3.0.0

Added:
- Add `in:` option to inputs to ensure they match a given collection (#25)
- Add support for instances of Interactor when using `play` (#29)

Breaking changes:
- Dropped deprecated support for `call!` on an actor.
- Dropped deprecated support for `succeed!` inside an actor.
- Dropped deprecated support for `context` inside an actor.
- Dropped deprecated support for `required` in input and output definitions.

## v2.0.0

Breaking changes:
- Disallow nil when a type is set by default and the default is not nil.

Added:
- Move all code inside `ServiceActor`, only exposing a base `Actor`, enabling
  you to change the default class name.
- Rename `Actor::Context` to `ServiceActor::Result`.
- Deprecate `context.` in favor of `result.`.
- Outputs add writer methods inside your actors, so you can do `self.name =`
  instead of `result.name =`.
- Outputs adds reader methods as well, so you can use anything you just set on
  the result right away inside your actor.
- Deprecate `required: true` in favor of `allow_nil: false`.
- All errors inherit from `ServiceActor::Error`.
- In case of argument errors, raise an `ServiceActor::ArgumentError` instead of
  a `ArgumentError`.
- Allow classes as well as strings in type definitions.
- Deprecate early success in favor of play conditions.

Fixes:
- Allow inputs and outputs called `before`, `after` and `run`.
- Do not raise an error when accessing `result.` with unknown inputs or
  outputs.

## v1.1.0

Added:
- An error is raised if inputs have not been given and have no default.
- Fix assigning hashes and blocks to the output.
- Add compatibility to organizers from the Interactor gem.

## v1.0.0

Added:
- First version \o/
