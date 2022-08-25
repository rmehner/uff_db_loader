# frozen_string_literal: true

module UffDbLoader
  module Postgresql
    def self.dump_extension
      "dump"
    end

    def self.dump_command_template
      "ssh %user%@%host% \"docker exec -i %app_name%_%environment%_db sh -c 'exec pg_dump --username \\$POSTGRES_USER --clean --no-owner --no-acl --format=c %database%'\" > %target%"
    end

    def self.restore_command(database_name, result_file_path)
      "pg_restore --username postgres --clean --if-exists --no-owner --no-acl --dbname #{database_name} #{result_file_path}"
    end

    def self.list_databases(rolename)
      ActiveRecord::Base
        .connection
        .execute("SELECT datname FROM pg_database JOIN pg_authid ON pg_database.datdba = pg_authid.oid WHERE rolname = '#{rolename}';")
        .values
        .flatten
    end

    def self.create_database
      ActiveRecord::Base.connection.execute("CREATE DATABASE #{database_name};")
    end

    def self.drop_database
      ActiveRecord::Base.connection.execute("DROP DATABASE IF EXISTS #{database_name};")
    end
  end
end
