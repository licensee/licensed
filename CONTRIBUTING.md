## Contributing

[fork]: https://github.com/github/licensed/fork
[pr]: https://github.com/github/licensed/compare
[style]: https://github.com/styleguide/ruby
[code-of-conduct]: CODE_OF_CONDUCT.md

Hi there! We're thrilled that you'd like to contribute to this project. Your help is essential for keeping it great.

Please note that this project is released with a [Contributor Code of Conduct][code-of-conduct]. By participating in this project you agree to abide by its terms.

## Submitting a pull request

0. [Fork][fork] and clone the repository
0. Configure and install the dependencies: `script/bootstrap`
0. Setup test fixtures: `bundle exec rake setup`
0. Make sure the tests pass on your machine: `bundle exec rake test`
0. Create a new branch: `git checkout -b my-branch-name`
0. Make your change, add tests, and make sure the tests still pass
0. Push to your fork and [submit a pull request][pr]
0. Pat your self on the back and wait for your pull request to be reviewed and merged.

Here are a few things you can do that will increase the likelihood of your pull request being accepted:

- Follow the [style guide][style].
- Write tests.
- Keep your change as focused as possible. If there are multiple changes you would like to make that are not dependent upon each other, consider submitting them as separate pull requests.
- Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

#### Running tests locally

Use the source tool versions tested in [.github/workflows/test.yml](.github/workflows/test.yml), rather than assuming the newest releases are compatible with the fixtures. Install each source's dependencies with `script/source-setup/<source>` before running `script/test <source>`. `script/test core` runs the core and shared source-helper tests without requiring source toolchains.

`script/setup` attempts all source setup scripts, skips unavailable tools, and exits unsuccessfully if any setup script fails. Fix the reported failures before running the full suite. Installers may rewrite tracked fixture lockfiles; review those changes separately from your code changes.

`script/cibuild` runs the complete test suite, lint, and gem packaging. Unlike the individual CI jobs, it includes source suites currently disabled in CI. The Gradle fixtures have been verified locally with Gradle 8.5 and Java 21. Python fixtures require their populated virtual environments; select the fixture interpreter with `PIPENV_PYTHON` when multiple Python versions are installed.

For persistent machine-local tool selection, put exported POSIX shell variables such as `PATH`, `JAVA_HOME`, and `PIPENV_PYTHON` in `.licensed-dev-env` at the repository root. The build, setup, test, and individual source setup scripts load this optional, gitignored file before checking tools or running commands, so fixture preparation and tests use the same configuration. Without it, the scripts use the calling environment as before. Keep machine-specific runtime paths out of commits.

#### Adding a new Dependency Source

Pull requests that include a new dependency source must also

- Include [documentation](docs/sources) for the new source and update the [documented source list](README.md#sources).
- Add a [setup script](script/source-setup) if needed.
- Include [tests](test/source) and [test fixtures](test/fixtures) needed to verify the source in CI.
- Add a CI job to [.github/workflows/test.yml](.github/workflows/test.yml).

## Releasing
If you are the current maintainer of this gem:

Release versions are derived from Git tags, not manually bumped in `lib/licensed/version.rb`.
At an exact tag such as `v5.1.1`, the gem builds as `5.1.1`. Commits after a release tag
infer the next patch version. To test a minor or major release's exact version, create
the intended release tag locally on the candidate commit before building.

1. Create a branch for the release: git checkout -b cut-release-xx.xx.xx
2. Make sure your local dependencies are up to date: `script/bootstrap`
3. Ensure that tests are green: `bundle exec rake test`
4. Choose the release version and corresponding Git tag; do not edit the version constant.
5. Update [`CHANGELOG.md`](CHANGELOG.md)
6. Make a PR to licensee/licensed.
7. Build a local gem: bundle exec rake build
8. Test the gem:
   1. Bump the Gemfile and Gemfile.lock versions for an app which relies on this gem
   2. Install the new gem locally
   3. Test behavior locally, branch deploy, whatever needs to happen
9. Merge licensee/licensed PR
10. Create a new [licensee/licensed release](https://github.com/licensee/licensed/releases)
   - Set the release name and tag to the release version, using a tag such as `v5.1.1` on the intended release commit.
   - Set the release body to the changelog entries for the release

The following steps will happen automatically from a GitHub Actions workflow
after creating the release. In case that fails, the following steps can be performed manually

11. Push the gem from (7) to rubygems.org -- `gem push licensed-x.xx.xx.gem`

## Resources

- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [Using Pull Requests](https://help.github.com/articles/about-pull-requests/)
- [GitHub Help](https://help.github.com)
