# frozen_string_literal: true

require "tty-prompt"

namespace :remote_database do
  desc "Dumps a remote database to #{UffDbLoader.config.dumps_directory}"
  task dump: :environment do
    puts "🧐 Please note this task is called 'uff_db_loader:dump' now."
    Rake::Task["uff_db_loader:dump"].invoke
  end

  desc "Gets a dump from remote and loads it into the local database"
  task load: :environment do
    puts "🧐 Please note this task is called 'uff_db_loader:load' now."
    Rake::Task["uff_db_loader:load"].invoke
  end

  desc "Delete all downloaded db dumps and emove all databases created by UffDbLoader"
  task prune: :environment do
    puts "🧐 Please note this task is called 'uff_db_loader:prune' now."
    Rake::Task["uff_db_loader:prune"].invoke
  end
end
