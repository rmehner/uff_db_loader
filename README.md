# UffDbLoader

## Description

`uff_db_loader` provides rake tasks to download and import databases in rails projects with a dockerized deployment that we use in multiple projects.

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'uff_db_loader'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install uff_db_loader

Run the installation script:

    $ bin/rails uff_db_loader:install

## Configuration

You can configure the gem by running the following during the initialization of the Rails app:
```ruby
UffDbLoader.configure do |config|
  config.environments = ['staging', 'production']
  config.ssh_user = 'Francina'
  config.ssh_host = 'host.of.yoursite'
  config.db_name = 'twotter'
  config.db_system = :postgresql # Possible values are 'postgresql' and 'mysql'.
  config.app_name = 'my_app' # Defaults to the Rails app name
  config.dumps_directory = '/path/to/dumps' # Defaults to Rails.root.join('dumps')
  config.database_config_file = 'path/to/database.yml' # Defaults to Rails.root.join('config', 'database.yml')
  config.container_name_fn = ->(app_name, environment) { "#{app_name}_#{environment}_custom_suffix" } # Defaults to "#{app_name}_#{environment}_db".
end
```
For example in a file like `config/initializers/uff_db_loader.rb`.

Make sure the app's database user has the superuser role. Otherwise the app will crash on startup due to missing permissions.

## Usage

`uff_db_loader` can be called like `bin/rails uff_db_loader:<task>` where `<task>` is one of the following:

- `dump`: Dumps a remote database from a selected environment and downloads it
- `restore`: Restores a downloaded dump into a local database
- `switch`: Selects a restored local database to use
- `switch_to_default`: Switches database back to the default development database
- `load`: Dumps a remote database from a selected environment and downloads it then restores and selects the database
- `prune`: Delete all downloaded db dumps and removes all databases created by UffDbLoader

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rmehner/uff_db_loader. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/rmehner/uff_db_loader/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the UffDbLoader project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/rmehner/uff_db_loader/blob/main/CODE_OF_CONDUCT.md).
