# frozen_string_literal: true

require "tty-prompt"

namespace :uff_db_loader do
  desc "Install uff_db_loader"
  task install: :environment do
    UffDbLoader.remember_database_name("") # ensure database file exists

    if UffDbLoader.setup_dynamic_database_name_in_config
      puts "🤖 Updated #{UffDbLoader.config.database_config_file}. Happy hacking, beep boop!"
    else
      puts "💩 Because YAML is a wonderful format, you need to adapt your config file by hand."
      puts "🆗 Go to #{UffDbLoader.config.database_config_file} and change the development database value to: #{UffDbLoader.database_name_template("default_database_name")}"
    end
  end

  desc "Dumps a remote database to #{UffDbLoader.config.dumps_directory}"
  task dump: :environment do
    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", UffDbLoader.config.environments)
    UffDbLoader.ensure_valid_environment!(environment)
    UffDbLoader.dump_from(environment)
  end

  desc "Gets a dump from remote and loads it into the local database"
  task load: :environment do
    UffDbLoader.ensure_installation!

    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", UffDbLoader.config.environments)
    UffDbLoader.ensure_valid_environment!(environment)
    result_file_path = UffDbLoader.dump_from(environment)

    puts "🤓 Reading from to #{result_file_path}"

    database_name = File.basename(result_file_path, ".*")
    UffDbLoader.load_dump_into_database(database_name)
  end

  desc "Loads an existing dump into the local database"
  task restore: :environment do
    UffDbLoader.ensure_installation!

    prompt = TTY::Prompt.new
    existing_dumps = Dir.glob("#{UffDbLoader.config.dumps_directory}/#{UffDbLoader.config.app_name}*").map { |f| File.basename(f, ".*") }
    database_name = prompt.select("Which dump should be restored?", existing_dumps)

    UffDbLoader.load_dump_into_database(database_name)
  end

  desc "Delete all downloaded db dumps and remove all databases created by UffDbLoader"
  task prune: :environment do
    UffDbLoader.databases.each do |database_name|
      puts "Dropping #{database_name}"
      UffDbLoader.drop_database(database_name)
    end

    puts "Removing dumps from #{UffDbLoader.config.dumps_directory}"
    UffDbLoader.prune_dump_directory
  end
end
