# frozen_string_literal: true

module UffDbLoader
  module Postgresql
    def self.dump_extension
      "dump"
    end

    def self.dump_command_template
      "ssh %user%@%host% \"docker exec -i %container_name% sh -c 'exec pg_dump --username \\$POSTGRES_USER --no-owner --no-acl --format=c %database%'\" > %target%"
    end

    def self.restore_command_template
      "%command% --username postgres --no-owner --no-acl --dbname %database% %file%"
    end

    def self.default_restore_command
      "pg_restore"
    end

    def self.list_databases
      ActiveRecord::Base
        .connection
        .execute("SELECT datname FROM pg_database;")
        .values
        .flatten
    end

    def self.create_database(database_name)
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name};")
    end

    def self.drop_database(database_name)
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{database_name};")
    end
  end
end
