# frozen_string_literal: true

require "tty-prompt"

namespace :uff_db_loader do
  desc "Install uff_db_loader"
  task install: :environment do
    if UffDbLoader.setup_dynamic_database_name_in_config
      puts "🤖 Updated #{UffDbLoader.config.database_config_file}. Happy hacking, beep boop!"
    else
      puts "💩 Because YAML is a wonderful format, you need to adapt your config file by hand."
      puts "🆗 Go to #{UffDbLoader.config.database_config_file} and change the development database value to: #{UffDbLoader.database_name_template('default_database_name')}"
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
    UffDbLoader.create_database(database_name)

    puts "🗂  Created database #{database_name}"

    command_successful = system(UffDbLoader.restore_command(database_name, result_file_path))
    raise "Command did not run succesful: #{UffDbLoader.restore_command(database_name, result_file_path)}" unless command_successful

    puts "✅ Succesfully loaded #{result_file_path} into #{database_name}"

    UffDbLoader.remember_database_name(database_name)
    system("bin/rails restart")

    puts "♻️ Restarted rails server with new database."
  end

  desc "Delete all downloaded db dumps and emove all databases created by UffDbLoader"
  task prune: :environment do
    UffDbLoader.databases.each do |database_name|
      puts "Dropping #{database_name}"
      UffDbLoader.drop_database(database_name)
    end

    puts "Removing dumps from #{UffDbLoader.config.dumps_directory}"
    UffDbLoader.prune_dump_directory
  end
end
