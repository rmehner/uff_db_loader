# frozen_string_literal: true

require 'tty-prompt'

raise ForbiddenEnvironmentError unless Rails.env.development?

namespace :remote_database do
  desc "Dumps a remote database to #{OpsoneRailsRemoteDb::DUMP_DIRECTORY}"
  task :dump, [:source] => [:environment] do
    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", OpsoneRailsRemoteDb.config.environments)
    OpsoneRailsRemoteDb.dump_from(environment)
  end

  desc "Gets a dump from remote and loads it into the local Postgres"
  task :load, [:source] => [:environment] do
    prompt = TTY::Prompt.new
    environment = prompt.select("Which environment should we get the dump from?", OpsoneRailsRemoteDb.config.environments)
    result_file_path = dump_from(environment)

    puts "🤓 Reading from to #{result_file_path}"

    database_name = File.basename(result_file_path).gsub(".dump", "")
    ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name};")
    puts "🗂 Created database #{database_name}"

    load_dump_command = "pg_restore --username postgres --clean --if-exists --no-owner --no-acl --dbname #{database_name} #{result_file_path}"
    command_successful = system(load_dump_command)
    raise "Command did not run succesful: #{load_dump_command}" unless command_successful

    puts "✅ Succesfully loaded #{result_file_path} into #{database_name}"

    puts "💩 Because YAML is a wonderful format, you need to adapt your config file by hand."
    puts "🆗 Go to #{OpsoneRailsRemoteDb::DATABASE_CONFIG_FILE} and change the development database value to: #{database_name}"
    puts "🧑🏾‍🏫 Don't forgot to restart the Rails server after changing the database config (`rails restart`)"
  end
end
