# Changelog

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

Added:
- In case of argument errors, raise an `Actor::ArgumentError` instead of a
  `ArgumentError`.
- All errors inherit from `Actor::Error`.

## v1.1.0

Added:
- An error is raised if inputs have not been given and have no default.
- Fix assigning hashes and blocks to the output.
- Add compatibility to organizers from the Interactor gem.

## v1.0.0

Added:
- First version \o/
