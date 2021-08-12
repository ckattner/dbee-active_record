# Dbee Active Record Provider

Dbee does not ship with a SQL generator by default.  This library plugs into Dbee to provide SQL generation via ActiveRecord.  Technically speaking: this library does not use ActiveRecord for anything except connection information.  All actual SQL generation is performed using Arel.  There is no actual coupling of your domain ActiveRecord subclasses to Dbee.

This library is a plugin for Dbee.  The Dbee repositories README file contains information about how to use the Data Model and Query API's.

## Installation

To install through Rubygems:

````
gem install dbee-active_record
````

You can also add this to your Gemfile:

````
bundle add dbee-active_record
````

## Contributing

### Development Environment Configuration

Basic steps to take to get this repository compiling:

1. Install [Ruby](https://www.ruby-lang.org/en/documentation/installation/) (check dbee-active_record.gemspec for versions supported)
2. Install bundler (gem install bundler)
3. Clone the repository (git clone git@github.com:bluemarblepayroll/dbee-active_record.git)
4. Navigate to the root folder (cd dbee-active_record)
5. Install dependencies (bundle)
6. Copy spec/config/database.yaml.ci to spec/config/database.yaml. Customize both sqlite and mysql connections per your local environment.

### Running Tests

To execute the test suite run:

````bash
bundle exec rspec spec --format documentation
````

Alternatively, you can have Guard watch for changes:

````bash
bundle exec guard
````

Also, do not forget to run Rubocop:

````bash
bundle exec rubocop
````

### ActiveRecord Dependency

This library supports both ActiveRecord 5 and 6.  Tests are adapted for both versions and should be ran against both to ensure compatibility.  By default the latest 6 will be chosen unless overridden.

To install gems targeting version 5, run rubocop, and run rspec:

````shell
AR_VERSION=5 bundle update; AR_VERSION=5 bundle exec rake
````

To install gems targeting version 6, run rubocop, and run rspec:

````shell
AR_VERSION=6 bundle update; AR_VERSION=5 bundle exec rake
````

### Publishing

Note: ensure you have proper authorization before trying to publish new versions.

After code changes have successfully gone through the Pull Request review process then the following steps should be followed for publishing new versions:

1. Merge Pull Request into master
2. Update `version.rb` using [semantic versioning](https://semver.org/)
3. Install dependencies: `bundle`
4. Update `CHANGELOG.md` with release notes
5. Commit & push master to remote and ensure CI builds master successfully
6. Run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Code of Conduct

Everyone interacting in this codebase, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bluemarblepayroll/dbee-active_record/blob/master/CODE_OF_CONDUCT.md).

## License

This project is MIT Licensed.
