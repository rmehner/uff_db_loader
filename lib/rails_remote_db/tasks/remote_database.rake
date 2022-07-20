# frozen_string_literal: true

require 'tty-prompt'

raise ForbiddenEnvironmentError unless Rails.env.development?

namespace :remote_database do
  desc "Dumps a remote database to #{RailsRemoteDb::DUMP_DIRECTORY}"
  task dump: :environment do
    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", RailsRemoteDb.config.environments)
    RailsRemoteDb.dump_from(environment)
  end

  desc "Gets a dump from remote and loads it into the local Postgres"
  task load: :environment do
    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", RailsRemoteDb.config.environments)
    result_file_path = RailsRemoteDb.dump_from(environment)

    puts "🤓 Reading from to #{result_file_path}"

    database_name = File.basename(result_file_path).gsub(".dump", "")
    ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name};")

    puts "🗂  Created database #{database_name}"

    command_successful = system(RailsRemoteDb.restore_command(database_name, result_file_path))
    raise "Command did not run succesful: #{RailsRemoteDb.restore_command(database_name, result_file_path)}" unless command_successful

    puts "✅ Succesfully loaded #{result_file_path} into #{database_name}"
    puts "💩 Because YAML is a wonderful format, you need to adapt your config file by hand."
    puts "🆗 Go to #{RailsRemoteDb::DATABASE_CONFIG_FILE} and change the development database value to: #{database_name}"
    puts "🧑🏾‍🏫 Don't forgot to restart the Rails server after changing the database config (`rails restart`)"
  end
end
