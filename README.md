# UffDbLoader

## Description

`uff_db_loader` provides rake tasks to download and import databases in rails projects with a dockerized deployment that we use in multiple projects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'uff_db_loader'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install uff_db_loader

## Configuration

You can configure the gem by running the following during the initialization of the Rails app:
```ruby
# frozen_string_literal: true

UffDbLoader.configure do |config|
  config.environments = ['sandbox', 'production'] # default is "['staging', 'production']"
  config.ssh_user = 'Francina'
  config.ssh_host = 'host.of.yoursite'
  config.db_name = 'twotter'
  config.db_system = :postgresql # Possible values are 'postgresql' and 'mysql'.
end
```
For example in a file like `config/initializers/uff_db_loader.rb`.

Make sure the app's database user has the superuser role. Otherwise the app will crash on startup due to missing permissions.

## Usage

`uff_db_loader` provides `rails remote_database:dump` and `rails remote_database:load` which will prompt for a configured environment.
`dump` will only create and download a current database dump, while `load`, will do the same and restore the database content into a new database and gives instructions on how to use it in development.



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rmehner/uff_db_loader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/rmehner/uff_db_loader/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the UffDbLoader project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rmehner/uff_db_loader/blob/main/CODE_OF_CONDUCT.md).
