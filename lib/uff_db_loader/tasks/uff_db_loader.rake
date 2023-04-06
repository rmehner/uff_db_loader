# frozen_string_literal: true

require "tty-prompt"

namespace :uff_db_loader do
  desc "Set up UffDbLoader"
  task install: :environment do
    UffDbLoader.create_initializer

    UffDbLoader.log "👶 Created a Rails initializer file at #{UffDbLoader.initializer_path}."

    if UffDbLoader.setup_dynamic_database_name_in_config
      UffDbLoader.log "🤖 Updated #{UffDbLoader.config.database_config_file}. Happy hacking, beep boop!"
    else
      UffDbLoader.log "💩 Because YAML is a wonderful format, you need to adapt your config file by hand."
      UffDbLoader.log "🆗 Go to #{UffDbLoader.config.database_config_file} and change the development database value to: #{UffDbLoader.database_name_template("default_database_name")}"
    end
  end

  desc "Dumps a remote database from a selected environment to #{UffDbLoader.config.dumps_directory}"
  task dump: :environment do
    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", UffDbLoader.config.environments, filter: true)
    UffDbLoader.ensure_valid_environment!(environment)
    UffDbLoader.dump_from(environment)
  end

  desc "Restores a downloaded dump into a local database"
  task restore: :environment do
    UffDbLoader.ensure_installation!

    # switch to default db so we can restore the currently connected database
    UffDbLoader.remember_database_name("")
    ActiveRecord::Base.remove_connection
    ActiveRecord::Base.establish_connection(Rails.configuration.database_configuration["development"])

    prompt = TTY::Prompt.new
    database_name = prompt.select("Which dump should be restored?", UffDbLoader.dumps, filter: true)

    UffDbLoader.load_dump_into_database(database_name)
  end

  desc "Selects a restored local database to use"
  task switch: :environment do
    UffDbLoader.ensure_installation!

    prompt = TTY::Prompt.new
    databases = UffDbLoader.databases
    new_database = prompt.select("Which database do you want to switch to?", databases, filter: true)

    UffDbLoader.remember_database_name(new_database)
    UffDbLoader.restart_rails_server

    UffDbLoader.log "♻️  Restarted rails server with new database."
  end

  desc "Dumps a remote database from a selected environment to #{UffDbLoader.config.dumps_directory}, then restores and selects the database"
  task load: :environment do
    UffDbLoader.ensure_installation!

    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", UffDbLoader.config.environments, filter: true)
    UffDbLoader.ensure_valid_environment!(environment)
    result_file_path = UffDbLoader.dump_from(environment)

    UffDbLoader.log "🤓 Reading from to #{result_file_path}"

    database_name = File.basename(result_file_path, ".*")
    UffDbLoader.load_dump_into_database(database_name)
  end

  desc "Delete all downloaded db dumps and removes all databases created by UffDbLoader"
  task prune: :environment do
    UffDbLoader.databases.each do |database_name|
      next if database_name == ActiveRecord::Base.connection.current_database

      UffDbLoader.log "Dropping #{database_name}"
      UffDbLoader.drop_database(database_name)
    end

    UffDbLoader.log "Removing dumps from #{UffDbLoader.config.dumps_directory}"
    UffDbLoader.prune_dump_directory
  end

  desc "Switch back to default database"
  task switch_to_default: :environment do
    UffDbLoader.remember_database_name("")
    UffDbLoader.restart_rails_server

    UffDbLoader.log "♻️  Restarted rails server with default database."
  end
end
