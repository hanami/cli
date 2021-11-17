# Hanami::CLI
Hanami Command Line Interface

## v2.0.0.alpha3 - 2021-11-09
No changes.

## v2.0.0.alpha2 - 2021-05-04
### Added
- [Luca Guidi] Official support for Ruby: MRI 3.0
- [Luca Guidi] Dynamically change the set of available commands depending on the context (outside or inside an Hanami app)
- [Luca Guidi] Dynamically change the set of available commands depending on Hanami app architecture
- [Luca Guidi] Implemented `hanami version` (available both outside and inside an Hanami app)
- [Piotr Solnica] Implemented `db *` commands (available both outside and inside an Hanami app) (sqlite and postgres only for now)
- [Piotr Solnica] Implemented `console` command with support for `IRB` and `Pry` (`pry` is auto-detected)

### Changed
- [Luca Guidi] Changed the purpose of this gem: the CLI Ruby framework has been extracted into `dry-cli` gem. `hanami-cli` is now the `hanami` command line.
- [Luca Guidi] Drop support for Ruby: MRI 2.5.

## v1.0.0.alpha1 - 2019-01-30
### Added
- [Luca Guidi] Inheritng from subclasses of `Hanami::CLI::Command`, allows to inherit arguments, options, description, and examples.
- [Luca Guidi] Allow to use `super` from `#call`

### Changed
- [Luca Guidi] Drop support for Ruby: MRI 2.3, and 2.4.

## v0.3.1 - 2019-01-18
### Added
- [Luca Guidi] Official support for Ruby: MRI 2.6
- [Luca Guidi] Support `bundler` 2.0+

## v0.3.0 - 2018-10-24

## v0.3.0.beta1 - 2018-08-08
### Added
- [Anton Davydov & Alfonso Uceda] Introduce array type for arguments (`foo exec test spec/bookshelf/entities spec/bookshelf/repositories`)
- [Anton Davydov & Alfonso Uceda] Introduce array type for options (`foo generate config --apps=web,api`)
- [Alfonso Uceda] Introduce variadic arguments (`foo run ruby:latest -- ruby -v`)
- [Luca Guidi] Official support for JRuby 9.2.0.0

### Fixed
- [Anton Davydov] Print informative message when unknown or wrong option is passed (`"test" was called with arguments "--framework=unknown"`)

## v0.2.0 - 2018-04-11

## v0.2.0.rc2 - 2018-04-06

## v0.2.0.rc1 - 2018-03-30

## v0.2.0.beta2 - 2018-03-23
### Added
- [Anton Davydov & Luca Guidi] Support objects as callbacks

### Fixed
- [Anton Davydov & Luca Guidi] Ensure callbacks' context of execution (aka `self`) to be the command that is being executed

## v0.2.0.beta1 - 2018-02-28
### Added
- [Anton Davydov] Register `before`/`after` callbacks for commands

## v0.1.1 - 2018-02-27
### Added
- [Luca Guidi] Official support for Ruby: MRI 2.5

### Fixed
- [Alfonso Uceda] Ensure default values for arguments to be sent to commands
- [Alfonso Uceda] Ensure to fail when a missing required argument isn't provider, but an option is provided instead

## v0.1.0 - 2017-10-25

## v0.1.0.rc1 - 2017-10-16

## v0.1.0.beta3 - 2017-10-04

## v0.1.0.beta2 - 2017-10-03
### Added
- [Alfonso Uceda] Allow default value for arguments

## v0.1.0.beta1 - 2017-08-11
### Added
- [Alfonso Uceda, Luca Guidi] Commands banner and usage
- [Alfonso Uceda] Added support for subcommands
- [Alfonso Uceda] Validations for arguments and options
- [Alfonso Uceda] Commands arguments and options
- [Alfonso Uceda] Commands description
- [Alfonso Uceda, Oana Sipos] Commands aliases
- [Luca Guidi] Exit on unknown command
- [Luca Guidi, Alfonso Uceda, Oana Sipos] Command lookup
- [Luca Guidi, Tim Riley] Trie based registry to register commands and allow third-parties to override/add commands
