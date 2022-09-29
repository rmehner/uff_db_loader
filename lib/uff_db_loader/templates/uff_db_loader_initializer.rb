# frozen_string_literal: true

# Check out our README: https://github.com/rmehner/uff_db_loader/blob/main/README.md

if defined?(UffDbLoader)
  UffDbLoader.configure do |config|
    config.ssh_user = 'SSH_USER'
    config.ssh_host = 'HOST_OF_YOUR_SITE'
    config.db_name = 'YOUR_DATABASE_NAME'
    config.db_system = :postgresql # Possible values are :postgresql and :mysql

    # Optional settings:
    # config.environments = ['sandbox', 'production'] # default is "['staging', 'production']"
    # config.app_name = 'my_app' # Defaults to the Rails app name
    # config.dumps_directory = '/path/to/dumps' # Defaults to Rails.root.join('dumps')
    # config.database_config_file = 'path/to/database.yml' # Defaults to Rails.root.join('config', 'database.yml')
  end
end
