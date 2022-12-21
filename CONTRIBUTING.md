# Contributing to ServiceActor

Bug reports and pull requests are welcome
[on GitHub](https://github.com/sunny/actor).

## Code of Conduct

This project is intended to be a safe, welcoming space for collaboration, and
everyone interacting in the project’s codebase and issue tracker is expected to
adhere to the [Contributor Covenant code of
conduct](https://github.com/sunny/actor/blob/main/CODE_OF_CONDUCT.md).

## License

By contributing, you agree that your contributions will be licensed under the
[MIT License](https://choosealicense.com/licenses/mit/).

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Then, run `bin/rake` to run the tests and linting.

You can also run `bin/console` for an interactive prompt.

## Changelog

On a pull request, you can add an entry to the
[changelog](https://github.com/sunny/actor/blob/main/CHANGELOG.md) under the
“unreleased” section.

## Releases

To release a new version, update the version number in `version.rb`, and in the
`CHANGELOG.md`. Update the `README.md` if there are missing segments, make sure
tests and linting are pristine by calling `bundle && bin/rake`, then create a
commit for this version, for example with:

```sh
git add --patch
git commit -m "v`ruby -Ilib -rservice_actor/version -e "puts ServiceActor::VERSION"` 🎉"
```

You can then run `rake release`, which will assign a git tag, push using git,
and push the gem to [rubygems.org](https://rubygems.org).
