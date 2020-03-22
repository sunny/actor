# Changelog

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

Breaking changes:
- Move all code inside `ServiceActor`, only exposing a base `Actor`, enabling
  you to change the default class name.

Added:
- Rename `Actor::Context` to `Actor::Result`.
- Deprecate `context.` in favor of `result.`.
- Outputs add writer methods inside your actors, so you can do `self.name =`
  instead of `context.name =`.
- Outputs adds reader methods as well, so you can use anything you just set on
  the context right away inside your actor.
- Deprecate `required: true` in favor of `allow_nil: false`.
- In case of argument errors, raise an `Actor::ArgumentError` instead of a
  `ArgumentError`.
- All errors inherit from `Actor::Error`.
- Do not raise an error when accessing `context.` with unknown inputs or
  outputs.

Fixes:
- Do not expose methods called `before`, `after` and `run` in actors.

## v1.1.0

Added:
- An error is raised if inputs have not been given and have no default.
- Fix assigning hashes and blocks to the output.
- Add compatibility to organizers from the Interactor gem.

## v1.0.0

Added:
- First version \o/
