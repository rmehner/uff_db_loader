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
    environment = prompt.select("Which environment should we get the dump from?", UffDbLoader.config.environments,
      filter: true)
    UffDbLoader.ensure_valid_environment!(environment)
    UffDbLoader.dump_from(environment)
  end

  desc "Restores a downloaded dump into a local database"
  task restore: :environment do
    UffDbLoader.ensure_installation!

    UffDbLoader.connect_to_default_database

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
    UffDbLoader.connect_to_default_database

    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", UffDbLoader.config.environments,
      filter: true)
    UffDbLoader.ensure_valid_environment!(environment)
    result_file_path = UffDbLoader.dump_from(environment)

    UffDbLoader.log "🤓 Reading from #{result_file_path}"

    database_name = File.basename(result_file_path, ".*")
    UffDbLoader.load_dump_into_database(database_name)
  end

  desc "Delete downloaded db dumps and databases created by UffDbLoader. Pass a number of days (e.g. prune[7]) to only prune those older than that."
  task :prune, [:older_than_days] => :environment do |_task, args|
    max_age = args[:older_than_days] && (args[:older_than_days].to_i * 24 * 60 * 60)

    UffDbLoader.databases.each do |database_name|
      next if database_name == ActiveRecord::Base.connection.current_database
      next if max_age && !UffDbLoader.older_than?(database_name, max_age)

      UffDbLoader.log "Dropping #{database_name}"
      UffDbLoader.drop_database(database_name)
    end

    UffDbLoader.log "Removing dumps from #{UffDbLoader.config.dumps_directory}"
    UffDbLoader.prune_dump_directory(max_age)
  end

  desc "Switch back to default database"
  task switch_to_default: :environment do
    UffDbLoader.remember_database_name("")
    UffDbLoader.restart_rails_server

    UffDbLoader.log "♻️  Restarted rails server with default database."
  end

  desc "Shows the currently selected and connected database"
  task current: :environment do
    UffDbLoader.ensure_installation!
    selected_database = UffDbLoader.current_database_name

    UffDbLoader.log "Active Record connected to: #{ActiveRecord::Base.connection.current_database}"
    UffDbLoader.log "Selected database: #{selected_database}" unless selected_database.nil?
  end
end
