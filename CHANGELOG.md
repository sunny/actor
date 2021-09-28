# Changelog

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## unreleased

## v3.1.2

Fixes:
- The `in:` option supports the `default:` keyword as well.

## v3.1.1

Fixes:
- Ruby 2.4 and 3 support

## v3.1.0

Added:
- Add `fail_on` to catch argument errors and turn them into actor failures.

Fixes:
- Harmonize error messages by removing trailing dots.

## v3.0.0

Added:
- Add `in:` option to inputs to ensure they match a given collection.
- Add support for instances of Interactor when using `play`.

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
