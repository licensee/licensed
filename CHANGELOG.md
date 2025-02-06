# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## 5.0.2

- Pin setup-ruby and set permissions in test workflow (<https://github.com/licensee/licensed/pull/768>)
- Pin action versions in test.yml (<https://github.com/licensee/licensed/pull/776>)
- Add `csv` as a dependency for Ruby 3.4+ (<https://github.com/licensee/licensed/pull/786>)
- Fix `nil` bug when there's no `dependency` key in `package.json` (<https://github.com/licensee/licensed/pull/791>)

## 5.0.1

- Updated dependencies as needed for security fixes

## 5.0.0

### Breaking change

- Only supports Ruby 3.0+ due to nokogiri upgrade

### Changed

- Ensure homepage string is not too long in cabal.rb to avoid DOS attack
- Update dependencies

## 4.5.0

### Changed

- Bumped a number of dependencies for security fixes

## 4.4.0

### Added

- Licensed status command will alert on stale cached dependency records (<https://github.com/github/licensed/pull/657>)

## 4.3.1

### Changed

- Bump nokogiri to resolve vulnerabilities (<https://github.com/github/licensed/pull/648>)

## 4.3.0

### Added

- Cocoapods support has been re-enabled using a cocoapods plugin (<https://github.com/github/licensed/pull/644>)

## 4.2.0

### Added

- Reviewed and ignored configuration lists support matching on versions and version ranges (<https://github.com/github/licensed/pull/629>)

### Fixed

- Licensed should more reliably source dependencies from Gradle >= 8.0 (<https://github.com/github/licensed/pull/630>)

## 4.1.0

### Added

- Custom license terms can be added to dependencies via new configuration options (<https://github.com/github/licensed/pull/624>)
- Licensed is now integrated with pnpm to enumerate dependencies (<https://github.com/github/licensed/pull/626>)

## 4.0.4

### Changed

- Dependency version requirements are more relaxed (<https://github.com/github/licensed/pull/619>)

## 4.0.3

### Changed

- Cocoapods dependency enumeration has been disabled (<https://github.com/github/licensed/pull/616>)

### Fixed

- Fixed method signature change in Bundler API with Bundler >= 2.4.4 (:tada: @CvX <https://github.com/github/licensed/pull/614>)
- Fixed installation dependency compatibility with Rails >= 7.0 (<https://github.com/github/licensed/pull/616>)

## 4.0.2

### Fixed

- The path to a gradlew executable can be configured when enumerating gradle dependencies (:tada: @LouisBoudreau <https://github.com/github/licensed/pull/610>)

## 4.0.1

### Fixed

- Running gradle tests will no longer fail when gradle is not available (<https://github.com/github/licensed/pull/606>)

## 4.0.0

### Added

- Licensed supports Cocoapods as a dependency source (:tada: @LouisBoudreau <https://github.com/github/licensed/pull/584>)
- Licensed supports Gradle multi-project builds (:tada: @LouisBoudreau <https://github.com/github/licensed/pull/583>)

### Fixed

- Licensed no longer crashes when run with Bundler >= 2.4.0 (:tada: @JoshReedSchramm <https://github.com/github/licensed/pull/597>)

### Changed

- BREAKING: Licensed no longer ships executables with releases (<https://github.com/github/licensed/pull/586>)
- BREAKING: Licensed no longer includes support for Go <= 1.11 (<https://github.com/github/licensed/pull/602>)

## 3.9.1

### Fixed

- Updating cached dependency records will more accurately apply `review_changed_license` flag (<https://github.com/github/licensed/pull/578>)

## 3.9.0

### Added

- `NOTICE` files can now be generated without cached files in a repository (<https://github.com/github/licensed/pull/572>)

## 3.8.0

### Added

- Licensing compliance status checks can now be used without cached files in a repository (<https://github.com/github/licensed/pull/560>)

## 3.7.5

### Fixed

- Python dependency metadata will be correctly parsed from the ouput of `pip show` (<https://github.com/github/licensed/pull/555>)

## 3.7.4

### Fixed

- Licenses for Python dependencies built with Hatchling are correctly found (<https://github.com/github/licensed/pull/547>)

## 3.7.3

### Fixed

- Swift test fixtures build artifacts are now ignored (:tada: @CvX <https://github.com/github/licensed/pull/524>)
- Running cargo test fixture setup no longer deletes test files (:tada: @CvX <https://github.com/github/licensed/pull/525>)
- Bundler test fixtures are compatible with latest macOS silicon(:tada: @CvX <https://github.com/github/licensed/pull/528>)
- Fix segfaults seen using licensed with ruby 3.0.4 (<https://github.com/github/licensed/pull/530>)
- Fix compatibility with latest versions of bundler 2.3 (<https://github.com/github/licensed/pull/535>)
- Fix compatibility with latest versions of bundler 2.3 (:tada: @CvX <https://github.com/github/licensed/pull/522>)

## 3.7.2

### Fixed

- Comparing dependency license contents now finds matching contents regardless of the order of the licenses (<https://github.com/github/licensed/pull/516>)
- Fixed typo in a link in README.md (<https://github.com/github/licensed/pull/514>)

### Changed

- Elixir testing setup is migrated to erlef/setup-beam (<https://github.com/github/licensed/pull/512>)

## 3.7.1

### Fixed

- Dependencies' legal notice file matching has been made more strict to reduce false positives on code files containing the word `legal` (<https://github.com/github/licensed/pull/510>)

## 3.7.0

### Changed

- Pip and pipenv sources will find dependency licenses under `dist-info/license_files` when available (<https://github.com/github/licensed/pull/504>)

## 3.6.0

2022-03-17

### Added

- Composer dev dependencies can optionally be included in enumerated PHP dependencies (:tada: @digilist <https://github.com/github/licensed/pull/486>)
- Getting started usage documentation (<https://github.com/github/licensed/pull/483>)
- Initial support for NPM workspaces (<https://github.com/github/licensed/pull/485>)

### Changed

- Transitive dependencies are now enumerated by the `pip` source (<https://github.com/github/licensed/pull/480>)

### Fixed

- `licensed cache --force` will now correctly overwrite existing license classifications (<https://github.com/github/licensed/pull/473>)

## 3.5.0

2022-02-24

### Added

- [Licensee](https://github.com/licensee/licensee) confidence thresholds can be configured in the licensed configuration file (<https://github.com/github/licensed/pull/455>)

## 3.4.4

2022-02-07

### Fixed

- The npm and pip sources have better protection from strings causing crashes in `Hash#dig` (<https://github.com/github/licensed/pull/450>)

## 3.4.3

2022-01-31

### Added

- The npm source handles more cases of missing, optional, peer dependencies (<https://github.com/github/licensed/pull/443>)

## 3.4.2

2022-01-17

### Fixed

- The yarn source will no longer evaluate package.json files that do not represent project dependencies (<https://github.com/github/licensed/pull/439>)

## 3.4.1

2022-01-07

### Fixed

- Malformed package.json files will no longer crash yarn dependency detection (<https://github.com/github/licensed/pull/431>)

## 3.4.0

2021-12-14

### Added

- New Yarn enumerator with support for berry versions (<https://github.com/github/licensed/pull/423>)

### Fixed

- Error handling cases return correct values in the Yarn enumerator (<https://github.com/github/licensed/pull/425>)
- Fixed link in command documentation (:tada: @chibicco <https://github.com/github/licensed/pull/416>)
- Fixed minor backwards compatibility issue for Ruby 2.3 support (:tada: @dzunk <https://github.com/github/licensed/pull/414>)

### Changed

- Licensed's own dependencies are cached in the repository and kept up to date with GitHub Actions (<https://github.com/github/licensed/pull/421>)

## 3.3.1

2021-10-07

### Fixed

- Fix evaluation of peer dependencies with npm 7 (:tada: @manuelpuyol <https://github.com/github/licensed/pull/411>)

### Changed

- Manifest source evaluation performance improvements (<https://github.com/github/licensed/pull/407>)

## 3.3.0

2021-09-18

### Added

- New cargo source enumerates rust dependencies (<https://github.com/github/licensed/pull/404>)

### Changed

- Removed non-functional files from gem builds (<https://github.com/github/licensed/pull/405>)

## 3.2.3

2021-09-14

### Fixed

- Bundler source will no longer infinitely recurse when enumerating specifications (<https://github.com/github/licensed/pull/402>)
- Using the `--sources` command line option will no longer delete skipped sources' cached files (<https://github.com/github/licensed/pull/401>)

## 3.2.2

2021-09-09

### Fixed

- Bundler source works properly again when used outside of `bundle exec` (<https://github.com/github/licensed/pull/397>)

## 3.2.1

2021-09-06

### Changed

- Updated multiple dependency versions (:tada: @mmorel-35 <https://github.com/github/licensed/pull/385>, <https://github.com/github/licensed/pull/389>)
- Go homepage links use pkg.go.dev instead of godoc.org (:tada: @mmorel-35 <https://github.com/github/licensed/commit/73cfbbe954a3e8c8cbaf8b68253053b157e01b79>)
- Local development ruby version changed to 2.7.4 (<https://github.com/github/licensed/pull/393>)

### Fixed

- Bundler source correctly finds platform specific dependencies (<https://github.com/github/licensed/pull/392>)

## 3.2.0

2021-08-19

### Added

- Application names can be dynamically generated based on the path to the application source  (<https://github.com/github/licensed/pull/375>)

### Changed

- Updated command documentation (<https://github.com/github/licensed/pull/378>, <https://github.com/github/licensed/pull/380/files>)
- Updated configuration documentation (<https://github.com/github/licensed/pull/375>)
- Cache and status commands give additional diagnostic output when using JSON and YAML formatters (<https://github.com/github/licensed/pull/378>)
- Status command will give users a link to documentation when compliance checks fail (<https://github.com/github/licensed/pull/381>)

### Fixed

- The bundler source correctly checks that the path bundler specifies a gem is loaded from is a file (<https://github.com/github/licensed/pull/379>)

## 3.1.0

2021-06-16

### Added

- Licensed supports Swift/Swift package manager as a dependency source (:tada: @mattt <https://github.com/github/licensed/pull/363>)'

### Changed

- The `source_path` configuration property accepts arrays of inclusion and exclusion glob patterns (<https://github.com/github/licensed/pull/368>)
- The Nuget source now uses configured fallback folders to find dependencies that are not in found in the project folder (<https://github.com/github/licensed/pull/366>)
- The Nuget source supports a configurable property for the path from the project source path to the project's `obj` folder (<https://github.com/github/licensed/pull/365>)

### Fixed

- The Go source's checks for local packages will correctly find paths in case-insensitive file systems (<https://github.com/github/licensed/pull/370>)
- The Bundler source will no longer unnecessarily reset the local Bundler environment configuration (<https://github.com/github/licensed/pull/372>)

## 3.0.1

2021-05-17

### Fixed

- The bundler source will correctly enumerate dependencies pulled with a `git:` directive (<https://github.com/github/licensed/pull/360>)

## 3.0.0

2021-04-27

**This is a major release and includes potentially breaking changes to bundler dependency enumeration.**

### Changed

- The bundler source will return an error when run from an executable.  Please install licensed as a gem to continue using the bundler source.  Please see the [v3 migration document](./docs/migrations/v3.md) for full details and migration strategies.

## 2.15.2

2021-04-06

### Fixed

- The pip source works with package names containing periods (:tada: @bcskda <https://github.com/github/licensed/pull/350>)

## 2.15.1

2021-03-29

### Changed

- The npm source will ignore dependencies that are marked as both extraneous and missing (<https://github.com/github/licensed/pull/347>)

## 2.15.0

2021-03-24

### Added

- Support for npm 7 (<https://github.com/github/licensed/pull/341>)

### Fixed

- Files in the manifest source will be found correctly for apps that are not at the repository root (<https://github.com/github/licensed/pull/345>)

## 2.14.4

2021-02-09

### Added

- `list` and `cache` commands optionally print output in JSON or YML formats using the `--format/-f` flag (<https://github.com/github/licensed/pull/334>)
- `list` command will include detected license keys using the `--licenses/-l` flag (<https://github.com/github/licensed/pull/334>)

## 2.14.3

2020-12-11

### Fixed

- Auto-generating license text for a known license will no longer raise an error if the found license has no text (:tada: @Eun <https://github.com/github/licensed/pull/328>)

## 2.14.2

2020-11-20

### Fixed

- Yarn source correctly finds dependency paths on disk (<https://github.com/github/licensed/pull/326>)
- Go source better handles finding dependencies that have been vendored (<https://github.com/github/licensed/pull/323>)

## 2.14.1

2020-10-09

### Fixed

- Shell command output is encoded to UTF8 (<https://github.com/github/licensed/pull/319>)

## 2.14.0

2020-10-04

### Added

- `reviewed` dependencies can use glob pattern matching (<https://github.com/github/licensed/pull/313>)

### Fixed

- Fix configuring source path globs that expand into a single directory (<https://github.com/github/licensed/pull/312>)

## 2.13.0

2020-09-23

### Added

- `status` command results can be output in YAML and JSON formats (:tada: @julianvilas <https://github.com/github/licensed/pull/303>)

### Fixed

- `licensed` no longer crashes when parsing invalid YAML from cached records (<https://github.com/github/licensed/pull/306>)
- NPM source will no longer crash when invalid JSON is returned from npm CLI calls (<https://github.com/github/licensed/pull/300>)
- Bundler source is fixed to work properly with `gems.rb` lockfiles (<https://github.com/github/licensed/pull/299>)

## 2.12.2

2020-07-07

### Changed

- Cleaned up ruby 2.7 warnings (:tada: @jurre <https://github.com/github/licensed/pull/292>)
- Cleaned up additional warnings in tests (<https://github.com/github/licensed/pull/293>)

## 2.12.1

2020-06-30

### Fixed

- `licensed` no longer exits an error code when using the `--sources` CLI argument (<https://github.com/github/licensed/pull/290>)

## 2.12.0

2020-06-19

### Added

- `--sources` argument for cache, list, status and notices commands to filter running sources (<https://github.com/github/licensed/pull/287>)

### Fixed

- `cache` command will not remove files outside of enabled source cache paths (<https://github.com/github/licensed/pull/287>)

## 2.11.1

2020-06-09

### Fixed

- `notices` command properly reads cached dependency notices contents (<https://github.com/github/licensed/pull/283>)

## 2.11.0

2020-06-02

### Added

- `notices` command to create a `NOTICE` file for each configured app (<https://github.com/github/licensed/pull/277>)

### Fixed

- NuGet source no longer crashes on a non-existent dependency path (<https://github.com/github/licensed/pull/280>)
- Go source no longer crashes on a non-existent dependency package path (<https://github.com/github/licensed/pull/274>)

## 2.10.0

2020-05-15

### Changed

- NPM source ignores missing peer dependencies (<https://github.com/github/licensed/pull/267>)

### Added

- NuGet source (:tada: @zarenner <https://github.com/github/licensed/pull/261>)
- Multiple apps can share a single cache location (<https://github.com/github/licensed/pull/263>)

## 2.9.2

2020-04-28

### Changed

- `licensee` minimum version bumped to 9.13.2 (<https://github.com/github/licensed/pull/256>)

## 2.9.1

2020-03-24

### Changed

- relaxed gem version restrictions on Thor (:tada: @eileencodes <https://github.com/github/licensed/pull/254>)

## 2.9.0

2020-03-19

### Added

- Source paths use glob pattern matching (<https://github.com/github/licensed/pull/245>)

### Fixed

- Mix source supports updates to mix.lock format (:tada: @bruce <https://github.com/github/licensed/pull/242>)
- Go source supports `go list` format changes in go 1.14 (<https://github.com/github/licensed/pull/247>)

### Changed

- `licensed cache` will flag dependencies for re-review when license text changes (<https://github.com/github/licensed/pull/248>)
- `licensed status` will raise errors on dependencies that need re-review (<https://github.com/github/licensed/pull/248>)
- `licensee` minimum version bumped to 9.13.1 (<https://github.com/github/licensed/pull/251>)

## 2.8.0

2020-01-03

### Added

- Yarn source (<https://github.com/github/licensed/pull/232>, <https://github.com/github/licensed/pull/233>, <https://github.com/github/licensed/pull/236>)
- NPM source has a new option to include non-production dependencies (<https://github.com/github/licensed/pull/231>)

### Fixed

- Cabal source will no longer crash if packages aren't found (<https://github.com/github/licensed/pull/230>)

## 2.7.0

2019-11-10

### Added

- License text is automatically generated for known licenses when not otherwise available (<https://github.com/github/licensed/pull/223>)

### Changed

- Ignoring dependencies uses glob pattern matching (<https://github.com/github/licensed/pull/225>)

## 2.6.2

2019-11-03

### Changed

- A number of improvements to the go dependency enumerator
  - use `go env GOPATH` as a default if no other GOPATH is found
  - better compatibility with go modules when finding license content
  - better compatibility with vendored go modules
  - use a packages godoc.org page as it's homepage
  - better checks for standard packages, reducing the amount of cached content

## 2.6.1

2019-10-26

### Changed

- Performance improvements during dependency enumeration (:tada: @krzysztof-pawlik-gat <https://github.com/github/licensed/pull/204>, <https://github.com/github/licensed/pull/207>) (<https://github.com/github/licensed/pull/210>)

## 2.6.0

2019-10-22

### Added

- Mix source for Elixir (:tada: @bruce <https://github.com/github/licensed/pull/195>)

## 2.5.0

2019-09-26

### Added

- `env` command to output application environment configuration (<https://github.com/github/licensed/pull/187>, <https://github.com/github/licensed/pull/191>)

### Changed

- `status` command will pass if multiple allowed licenses are found (<https://github.com/github/licensed/pull/188>)

## 2.4.0

2019-09-15

### Added

- Composer source for PHP (<https://github.com/github/licensed/pull/182>)

## 2.3.2

2019-08-26

### Fixed

- Bundler with/without array settings are properly handled for bundler 1.15.x

## 2.3.1

2019-08-20

### Changed

- Using the npm source with yarn, "missing" dependencies are no longer considered errors (:tada: @krzysztof-pawlik-gat <https://github.com/github/licensed/pull/170>)
- The bundler source now calls `gem specification` with dependency version requirements (<https://github.com/github/licensed/pull/173>)

## 2.3.0

2019-05-19

### Added

- New Pipenv dependency source enumerator (:tada: @krzysztof-pawlik-gat <https://github.com/github/licensed/pull/167>)

## 2.2.0

2019-05-11

### Added

- Content hash versioning strategy for go and manifest sources (<https://github.com/github/licensed/pull/164>)

### Fixed

- Python source handles urls and package names with "-" in requirements.txt (:tada: @krzysztof-pawlik-gat <https://github.com/github/licensed/pull/165>)

## 2.1.0

2019-04-16

### Added

- New Gradle dependency source enumerator (:tada: @dbussink <https://github.com/github/licensed/pull/150>, @jandersson-svt <https://github.com/github/licensed/pull/159>)
- Metadata added to distributed packages (<https://github.com/github/licensed/pull/160>)

### Changes

- Bundler dependency source loads license key from a gem's cached gemspec file as a fallback (<https://github.com/github/licensed/pull/154>)
- Licensed will only raise errors on an empty dependency path when caching records (<https://github.com/github/licensed/pull/149>)

### Fixed

- Migrating to v2 will no longer crash trying to migrate cached records that don't exist (<https://github.com/github/licensed/pull/148>)
- Reported warnings will no longer crash licensed when caching records (<https://github.com/github/licensed/pull/147>)

## 2.0.1

2019-02-14

### Changes

- Dependency paths that don't exist on the local disk are reported as warnings
- Cache, status and list output is sorted by app name, source type and dependency name
- Bumped `licensee` gem requirement

## 2.0.0

2019-02-09

**This is a major release and includes breaking changes to the configuration and cached record file formats**

### Added

- New `migrate` command to automatically update configuration and cached record file formats
- New extensible reporting infrastructure
- New base command and source classes to abstract away implementation details

### Changes

- Cached dependency metadata files are now stored entirely as YAML, with `.dep.yml` extension
- The Bundler dependency source is now identified in configuration files and output as `bundler` instead of `rubygem`
- Refactored sources for better consistency between classes
- Refactored commands for better consistency between classes
- Command outputs have changed for better consistency
- Updated Dependency classes for better integration with `licensee`

### Fixed

- Licensed no longer exits on errors when evaluating dependency sources or finding dependencies
- The Bundler dependency source correctly finds the `bundler` gem as a dependency in more cases

## 1.5.2

2018-12-27

### Changes

- Go source added support for Go modules and Golang 1.11+ (<https://github.com/github/licensed/pull/113>)

### Fixed

- Licensed will have a non-zero exit code when commands fail (:tada: @parkr <https://github.com/github/licensed/pull/111>)

## 1.5.1

2018-10-30

### Fixed

- Fixed a scenario where licensed wasn't finding bundler dependencies when run as an executable due to a ruby version mismatch (<https://github.com/github/licensed/pull/106>)

## 1.5.0

2018-10-24

### Added

- `licensed (version | -v | --version)` command to see the current licensed version (:tada: @mwagz! <https://github.com/github/licensed/pull/101>)

### Fixed

- NPM source no longer raises an error when ignored dependencies aren't found (:tada: @mwagz! <https://github.com/github/licensed/pull/100>)
- Checking for a Git repo will no longer possibly modify `.git/index` (:tada: @dbussink <https://github.com/github/licensed/pull/102>)
- Fixed a scenario where licensed wasn't finding bundler dependencies when run as an executable (<https://github.com/github/licensed/pull/103>)

## 1.4.0

2018-10-20

### Added

- Git Submodules dependency source :tada:
- Configuration option to explicitly set a root absolute path

### Changes

- `COPYING` file is no longer matched as a legal file

### Fixed

- NPM source will enumerate multiple versions of the same dependency
- Running Licensed outside of a Git repository no longer raises an error
- Packaging scripts will correctly return to the previous branch when the script is finished

## 1.3.4

2018-09-20

### Changes

- Bundler source will avoid looking for a gemspec file when possible

## 1.3.3

2018-09-07

### Fixed

- Manifest source configuration globs correctly enumerates files from within submodules
- The manifest source no longer errors when getting version information from submodules

## 1.3.2

2018-08-15

### Fixed

- Fixed issue when multiple versions of a cabal package are found

## 1.3.1

2018-08-01

### Fixed

- Fixed regression finding ruby gems by path

## 1.3.0

2018-07-25

### Added

- Manifests for the manifest dependency source can be specified using glob patterns in the configuration
- Paths to licenses for dependencies from the manifest dependency source can be specified in the configuration
- Manifest dependency source looks for license content in C-style comments if a license file isn't found

## Changes

- GitHub is no longer queried to find remote license information
- Removed custom logic around determining whether to use the license key from `licensee`
- NPM dependency enumeration doesn't use `npm list`
- Licensed now tracks content from multiple license files when available

### Fixed

- Fixed regression finding platform-specific ruby gems

## 1.2.0

2018-06-22

### Added

- Building and packaging distributable exes for licensed releases
- Can now configure which Gemfile groups are excluded from dependency enumeration

### Fixed

- Bundler is no longer always reported as a dependency
- Set the minimum required ruby version for licensed

## 1.1.0

2018-06-04

### Added

- Pip dependency source :tada:
- Go Dep dependency source :tada:

### Changed

- Changed how `sources` configuration property affects which sources are enabled
- Raise informative error messages when shell commands fail

### Fixed

- Don't reuse cached license when cached version metadata is missing
- Disable dependency sources when dependent tools are not available
- Vendored packages from the go std library are properly excluded
- Cabal dependency enumeration properly includes executable targets

## 1.0.1

2018-04-26

### Added

- GOPATH settable in configuration file

### Changed

- Reuse "license" metadata property when license text has not changed

### Fixed

- Path expansion for cabal "ghc_package_db" configuration setting occurs from repository root
- Local Gemfile(.lock) files correctly used in enumerating Bundler source dependencies

## 1.0.0

2018-02-20

Initial release :tada:

[Unreleased]: https://github.com/github/licensed/compare/4.4.0...HEAD
